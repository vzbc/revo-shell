#define WLR_USE_UNSTABLE

#include <GLES3/gl32.h>

#include <hyprland/src/includes.hpp>

#include <chrono>
#include <cmath>
#include <sstream>
#include <string>
#include <vector>

#define private public
#define protected public
#include <hyprland/src/desktop/Workspace.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/render/Framebuffer.hpp>
#include <hyprland/src/render/OpenGL.hpp>
#include <hyprland/src/render/Renderer.hpp>
#include <hyprland/src/render/Shader.hpp>
#include <hyprland/src/render/pass/SurfacePassElement.hpp>
#include <hyprland/src/render/pass/TexPassElement.hpp>
#include <hyprland/src/render/transformer/Transformer.hpp>
#undef private
#undef protected

#include "globals.hpp"

extern "C" {
#include <lua.h>
#include <lauxlib.h>
}

// Genie warp: the window is rendered into its temp framebuffer as usual,
// then transform() wipes it and re-draws the content as a strip mesh whose
// rows bend toward the Dock icon — the funnel from the reference photos.
//
// Damage: amendTransformedRenderData() enables motion-blur with
// previous == current == full monitor box, which (samples = 1) is an
// identity sample AND makes the element's bounding box cover the whole
// monitor, so the funnel tail below the window is repainted every frame.

namespace {

constexpr int    STRIPS         = 120;
constexpr double TOP_HOLD       = 0.45; // photos: top edge anchored ~45% in
constexpr double BOTTOM_ARRIVE  = 0.55; // photos: tail parked in the Dock ~55% in

inline double sstep(double u) {
    if (u <= 0.0)
        return 0.0;
    if (u >= 1.0)
        return 1.0;
    return u * u * u * (u * (u * 6.0 - 15.0) + 10.0);
}

class CGenieTransformer : public Render::IWindowTransformer {
  public:
    CGenieTransformer(Vector2D tip, double tipHalf, double dur, bool restore) :
        m_tip(tip), m_tipHW(tipHalf > 1.0 ? tipHalf : 8.0), m_dur(dur > 0.05 ? dur : 0.36), m_restore(restore) {}

    ~CGenieTransformer() override = default;

    void preWindowRender(CSurfacePassElement::SRenderData* rd) override {
        const auto MON = g_pHyprRenderer->m_renderData.pMonitor;
        if (!MON || !rd)
            return;

        m_local  = {rd->pos.x - MON->m_position.x, rd->pos.y - MON->m_position.y};
        m_winsz  = {rd->w, rd->h};
        m_monsz  = MON->m_size;
        m_scale  = MON->m_scale;
        rd->blur = false; // no background blur box under the warped shape
    }

    void amendTransformedRenderData(const CBox& currentBox, SMotionBlurData* mb) override {
        if (!mb)
            return;
        mb->enabled  = true;
        mb->previous = mb->current = CBox{0, 0, m_monsz.x, m_monsz.y};
        mb->samples  = 1;
    }

    SP<Render::IFramebuffer> transform(SP<Render::IFramebuffer> in) override {
        if (!in || m_winsz.x < 2.0 || m_winsz.y < 2.0 || m_monsz.x < 1.0 || m_monsz.y < 1.0)
            return in;

        if (!m_shader && !initShader())
            return in;

        if (!m_started) {
            m_t0      = std::chrono::steady_clock::now();
            m_started = true;
        }

        const double el = std::chrono::duration<double>(std::chrono::steady_clock::now() - m_t0).count();
        double       p  = m_dur > 0.0 ? el / m_dur : 1.0;
        if (p < 0.0)
            p = 0.0;
        if (p > 1.0)
            p = 1.0;
        if (m_restore)
            p = 1.0 - p;

        buildMesh(p, in->m_size);

        in->bind();
        glDisable(GL_SCISSOR_TEST);
        glClearColor(0, 0, 0, 0);
        glClear(GL_COLOR_BUFFER_BIT);

        const Mat3x3 proj = g_pHyprRenderer->projectBoxToTarget(CBox{0, 0, m_monsz.x, m_monsz.y});

        glUseProgram(m_shader->m_program);
        m_shader->setUniformMatrix3fv(SHADER_PROJ, 1, GL_TRUE, proj.getMatrix());
        m_shader->setUniformInt(SHADER_TEX, 0);
        glActiveTexture(GL_TEXTURE0);
        in->getTexture()->bind();

        glBindVertexArray(m_shader->m_uniformLocations[SHADER_SHADER_VAO]);
        glBindBuffer(GL_ARRAY_BUFFER, m_shader->m_uniformLocations[SHADER_SHADER_VBO]);
        glBufferData(GL_ARRAY_BUFFER, static_cast<GLsizeiptr>(m_mesh.size() * sizeof(float)), m_mesh.data(), GL_STREAM_DRAW);
        glDrawArrays(GL_TRIANGLES, 0, STRIPS * 6);

        glBindVertexArray(0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        return in;
    }

  private:
    bool initShader() {
        static constexpr const char* FRAG = R"(#version 300 es
precision highp float;
uniform sampler2D tex;
in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
void main() { fragColor = texture(tex, v_texcoord); }
)";

        m_shader = std::make_unique<CShader>();
        if (!m_shader->createProgram(Render::GL::g_pHyprOpenGL->m_shaders->TEXVERTSRC, FRAG, true, true)) {
            m_shader.reset();
            return false;
        }
        return true;
    }

    void buildMesh(double p, const Vector2D& fb) {
        m_mesh.resize(static_cast<size_t>(STRIPS + 1) * 6 * 4);

        const double invW = 1.0 / m_monsz.x;
        const double invH = 1.0 / m_monsz.y;
        const double x0   = m_local.x, y0 = m_local.y;
        const double W    = m_winsz.x, H = m_winsz.y;
        const double uL   = (x0 * m_scale) / fb.x;
        const double uR   = ((x0 + W) * m_scale) / fb.x;

        float*       d = m_mesh.data();

        // previous strip row
        double pxL = 0, pxR = 0, py = 0, ptv = 0;
        bool   havePrev = false;

        for (int i = 0; i <= STRIPS; ++i) {
            const double v  = static_cast<double>(i) / STRIPS;
            const double k  = sstep((p - TOP_HOLD * (1.0 - v)) / ((BOTTOM_ARRIVE + (1.0 - v) * (1.0 - BOTTOM_ARRIVE)) - TOP_HOLD * (1.0 - v)));
            const double yo = y0 + v * H;
            const double y  = yo + (m_tip.y - yo) * k;

            const double cxo = x0 + W * 0.5;
            const double cx  = cxo + (m_tip.x - cxo) * k;
            const double hw  = (W * 0.5) + (m_tipHW - W * 0.5) * k;
            const double xl  = cx - hw;
            const double xr  = cx + hw;

            const double tv = ((y0 + v * H) * m_scale) / fb.y;

            // normalize to unit space (projectBoxToTarget maps unit -> monitor box)
            const double uxL = xl * invW, uxR = xr * invW, uy = y * invH;

            if (havePrev) {
                // two triangles: prev row -> this row (u coords of content rows ptv/tv)
                *d++ = pxL; *d++ = py; *d++ = uL; *d++ = ptv;
                *d++ = pxR; *d++ = py; *d++ = uR; *d++ = ptv;
                *d++ = uxL; *d++ = uy; *d++ = uL; *d++ = tv;

                *d++ = pxR; *d++ = py; *d++ = uR; *d++ = ptv;
                *d++ = uxR; *d++ = uy; *d++ = uR; *d++ = tv;
                *d++ = uxL; *d++ = uy; *d++ = uL; *d++ = tv;
            }

            pxL = uxL; pxR = uxR; py = uy; ptv = tv;
            havePrev = true;
        }
    }

    Vector2D                 m_local = {}, m_winsz = {}, m_monsz = {};
    double                   m_scale = 1.0;
    Vector2D                 m_tip;
    double                   m_tipHW = 8.0;
    double                   m_dur   = 0.36;
    bool                     m_restore = false;
    bool                     m_started = false;
    std::chrono::steady_clock::time_point m_t0;
    std::unique_ptr<CShader> m_shader;
    std::vector<float>       m_mesh;
};

inline std::vector<UP<Render::IWindowTransformer>>* transformersOf(const PHLWINDOW& w) {
    return w ? &w->m_transformers : nullptr;
}

inline PHLWINDOW windowFromAddr(const std::string& s) {
    uintptr_t addr = 0;
    try {
        addr = std::stoull(s, nullptr, 0);
    } catch (...) {
        return nullptr;
    }
    for (const auto& W : Desktop::windowState()->windows()) {
        if (reinterpret_cast<uintptr_t>(W.get()) == addr)
            return W;
    }
    return nullptr;
}

inline void stripGenie(const PHLWINDOW& w) {
    if (!w)
        return;
    std::erase_if(*transformersOf(w), [](const auto& t) { return dynamic_cast<CGenieTransformer*>(t.get()) != nullptr; });
}

} // namespace

static bool genieAttach(const std::string& addrS, double tx, double ty, double tw, double dur, bool restore, std::string& err) {
    const auto W = windowFromAddr(addrS);
    if (!W) {
        err = "genie: no such window";
        return false;
    }

    stripGenie(W);
    W->m_transformers.push_back(makeUnique<CGenieTransformer>(Vector2D{tx, ty}, tw, dur, restore));
    return true;
}

static bool genieDetach(const std::string& addrS, std::string& err) {
    const auto W = windowFromAddr(addrS);
    if (!W) {
        err = "geniedetach: no such window";
        return false;
    }

    stripGenie(W);
    return true;
}

// hl.plugin.genie.attach("0xADDR", tipX, tipY, tipHalfWidth, dur, "in"|"out")
static int luaGenieAttach(lua_State* L) {
    const char*  addr = luaL_checkstring(L, 1);
    const double tx   = luaL_checknumber(L, 2);
    const double ty   = luaL_checknumber(L, 3);
    const double tw   = luaL_checknumber(L, 4);
    const double dur  = luaL_checknumber(L, 5);
    const char*  dir  = luaL_checkstring(L, 6);

    std::string err;
    if (!genieAttach(addr, tx, ty, tw, dur, std::string_view(dir) == "out", err))
        return luaL_error(L, "%s", err.c_str());

    lua_pushboolean(L, 1);
    return 1;
}

// hl.plugin.genie.detach("0xADDR")
static int luaGenieDetach(lua_State* L) {
    const char* addr = luaL_checkstring(L, 1);

    std::string err;
    if (!genieDetach(addr, err))
        return luaL_error(L, "%s", err.c_str());

    lua_pushboolean(L, 1);
    return 1;
}

void registerGenieLua() {
    HyprlandAPI::addLuaFunction(PHANDLE, "genie", "attach", luaGenieAttach);
    HyprlandAPI::addLuaFunction(PHANDLE, "genie", "detach", luaGenieDetach);
}

void clearGenieTransformers() {
    HyprlandAPI::removeLuaFunction(PHANDLE, "genie", "attach");
    HyprlandAPI::removeLuaFunction(PHANDLE, "genie", "detach");
    for (const auto& W : Desktop::windowState()->windows())
        stripGenie(W);
}
