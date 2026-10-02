#define WLR_USE_UNSTABLE

#include <hyprland/src/includes.hpp>

#include <cstdint>
#include <format>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>

#define private public
#define protected public
#include <hyprland/src/config/supplementary/executor/Executor.hpp>
#include <hyprland/src/desktop/Workspace.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/protocols/XDGShell.hpp>
#include <hyprland/src/xwayland/XSurface.hpp>
#undef private
#undef protected

#include "globals.hpp"

void registerGenieLua();
void clearGenieTransformers();

inline constexpr const char* MIN_SCRIPT           = "/home/revo/.config/hypr/scripts/minimize_window.py";
inline constexpr const char* TOPLEVEL_CTOR_SYMBOL =
    "_ZN20CXDGToplevelResourceC1EN9Hyprutils6Memory14CSharedPointerI12CXdgToplevelEENS2_I19CXDGSurfaceResourceEE";

typedef void (*origToplevelCtor)(void*, void*, void*);

inline CFunctionHook* toplevelCtorHook = nullptr;

struct SWatchedWindow {
    PHLWINDOWREF        window;
    CHyprSignalListener listener;
};

inline std::unordered_map<Desktop::View::CWindow*, SWatchedWindow> gWatched;

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

static void runMinimizeCmd(const char* op, PHLWINDOW window, bool nofocus) {
    if (!window)
        return;

    const auto ADDR = reinterpret_cast<uintptr_t>(window.get());

    std::string cmd = std::format("{} {} 0x{:x}", MIN_SCRIPT, op, ADDR);
    if (nofocus)
        cmd += " nofocus";

    Config::Supplementary::executor()->spawnRaw(cmd);
}

static bool alreadyOnSpecial(PHLWINDOW window) {
    const auto WORKSPACE = window->m_workspace;
    if (!WORKSPACE)
        return false;
    return WORKSPACE->m_name.starts_with("special:");
}

static void handleRequest(PHLWINDOW window, bool wantMinimize) {
    if (!window || !window->m_isMapped)
        return;

    if (wantMinimize) {
        if (alreadyOnSpecial(window))
            return;
        runMinimizeCmd("min", window, false);
    } else {
        if (!alreadyOnSpecial(window))
            return;
        runMinimizeCmd("restore", window, false);
    }
}

static void watchWindow(PHLWINDOW window) {
    if (!window || gWatched.contains(window.get()))
        return;

    PHLWINDOWREF ref = window;

    if (window->m_xdgSurface && window->m_xdgSurface->m_toplevel) {
        WP<CXDGToplevelResource> toplevel = window->m_xdgSurface->m_toplevel;

        gWatched.insert_or_assign(window.get(),
                                  SWatchedWindow{ref, toplevel->m_events.stateChanged.listen([ref, toplevel]() {
                                      if (!toplevel)
                                          return;
                                      const auto WANTS = toplevel->m_state.requestsMinimize.value_or(false);
                                      handleRequest(ref.lock(), WANTS);
                                  })});
        return;
    }

    if (window->m_xwaylandSurface) {
        WP<CXWaylandSurface> surface = window->m_xwaylandSurface;

        gWatched.insert_or_assign(window.get(),
                                  SWatchedWindow{ref, surface->m_events.stateChanged.listen([ref, surface]() {
                                      if (!surface)
                                          return;

                                      const auto WANTS = surface->m_state.requestsMinimize.value_or(false);

                                      // xwm never clears this, so any later state message would replay the stale request
                                      surface->m_state.requestsMinimize.reset();

                                      handleRequest(ref.lock(), WANTS);
                                  })});
    }
}

static void forgetWindow(PHLWINDOW window) {
    if (window)
        gWatched.erase(window.get());

    std::erase_if(gWatched, [](const auto& entry) { return !entry.second.window; });
}

static void onToplevelCreated(void* thisptr, void* resource, void* owner) {
    (reinterpret_cast<origToplevelCtor>(toplevelCtorHook->m_original))(thisptr, resource, owner);

    auto* const TOPLEVEL = reinterpret_cast<CXDGToplevelResource*>(thisptr);

    if (!TOPLEVEL->m_resource || TOPLEVEL->m_resource->version() < 5)
        return;

    wl_array caps;
    wl_array_init(&caps);

    for (const uint32_t CAP : {static_cast<uint32_t>(XDG_TOPLEVEL_WM_CAPABILITIES_FULLSCREEN), static_cast<uint32_t>(XDG_TOPLEVEL_WM_CAPABILITIES_MAXIMIZE),
                               static_cast<uint32_t>(XDG_TOPLEVEL_WM_CAPABILITIES_MINIMIZE)}) {
        auto* const SLOT = reinterpret_cast<uint32_t*>(wl_array_add(&caps, sizeof(uint32_t)));
        if (!SLOT)
            break;
        *SLOT = CAP;
    }

    TOPLEVEL->m_resource->sendWmCapabilities(&caps);
    wl_array_release(&caps);
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    const std::string HASH        = __hyprland_api_get_hash();
    const std::string CLIENT_HASH = __hyprland_api_get_client_hash();

    if (HASH != CLIENT_HASH) {
        HyprlandAPI::addNotification(PHANDLE, "[minimize-hooks] Failure in initialization: Version mismatch (headers ver is not equal to running hyprland ver)", CHyprColor{1.0, 0.2, 0.2, 1.0},
                                     5000);
        throw std::runtime_error("[minimize-hooks] Version mismatch");
    }

    auto fns = HyprlandAPI::findFunctionsByName(PHANDLE, TOPLEVEL_CTOR_SYMBOL);
    if (fns.empty())
        throw std::runtime_error("[minimize-hooks] CXDGToplevelResource ctor not found");

    toplevelCtorHook = HyprlandAPI::createFunctionHook(PHANDLE, fns[0].address, reinterpret_cast<void*>(&onToplevelCreated));

    if (!toplevelCtorHook->hook())
        throw std::runtime_error("[minimize-hooks] toplevel ctor hook failed");

    static auto P  = Event::bus()->m_events.window.open.listen([](PHLWINDOW window) { watchWindow(window); });
    static auto P2 = Event::bus()->m_events.window.close.listen([](PHLWINDOW window) { forgetWindow(window); });

    for (const auto& WINDOW : Desktop::windowState()->windows()) {
        watchWindow(WINDOW);
    }

    registerGenieLua();

    HyprlandAPI::addNotification(PHANDLE, "[minimize-hooks] Initialized successfully!", CHyprColor{0.2, 1.0, 0.2, 1.0}, 5000);

    return {"minimize-hooks", "Advertises the minimize capability and routes client minimize requests to minimize_window.py", "revo", "1.0"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    clearGenieTransformers();
    gWatched.clear();

    if (toplevelCtorHook) {
        toplevelCtorHook->unhook();
        toplevelCtorHook = nullptr;
    }
}
