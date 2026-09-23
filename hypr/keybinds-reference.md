# Keybinds — imperative-dots (مرجع للقراءة)
# هذا الملف للعرض فقط، الـ keybinds الفعلية في keybindings.conf

## Window Management
| Keybind | الوظيفة |
|---------|---------|
| ALT + F4 | إغلاق النافذة النشطة |
| Super + Shift + F | تعويم/إلغاء تعويم النافذة |
| Super + Shift + ←/→/↑/↓ | تغيير حجم النافذة |
| Super + Ctrl + ←/→/↑/↓ | نقل النافذة في الـ layout |
| Super + ←/→/↑/↓ | نقل التركيز بين النوافذ |
| Super + TAB | الانتقال للشاشة التالية (multi-monitor) |

## Applications
| Keybind | الوظيفة |
|---------|---------|
| Super + Enter | فتح الـ terminal (kitty) |
| Super + F | فتح Firefox |
| Super + E | فتح Nautilus (File Manager) |

## Quickshell Panels
| Keybind | الوظيفة |
|---------|---------|
| Super + D | App Launcher |
| Super + P | **Movies Widget** (عارض الأفلام) |
| Super + C | Clipboard Manager |
| Super + Q | Music Player |
| Super + B | Battery Info |
| Super + W | Wallpaper Picker |
| Super + S | Calendar |
| Super + N | Network/Bluetooth |
| Super + V | Volume Control |
| Super + H | Guide/Help |
| Super + Shift + S | Settings |
| Super + Shift + T | Focus Time |
| Super + R | إعادة تحميل الـ shell |

## System
| Keybind | الوظيفة |
|---------|---------|
| Super + L | قفل الشاشة |
| XF86PowerOff | قفل الشاشة |
| Print | Screenshot (منطقة) |
| Shift + Print | Screenshot + فتح في محرر |
| Super + Print | Screenshot كاملة |
| Super + Shift + Print | Screenshot كاملة + محرر |
| XF86MonBrightnessUp/Down | التحكم في السطوع |
| CapsLock | OSD للـ CapsLock |

## Media
| Keybind | الوظيفة |
|---------|---------|
| Super + Space | تشغيل/إيقاف مؤقت |
| XF86AudioPlay/Pause | تشغيل/إيقاف مؤقت |
| XF86AudioMicMute | كتم الميكروفون |
| XF86AudioMute | كتم الصوت |
| XF86AudioLower/RaiseVolume | التحكم في الصوت |

## Workspaces
| Keybind | الوظيفة |
|---------|---------|
| Super + 1-9, 0 | الانتقال لـ workspace رقم 1-10 |
| Super + Shift + 1-9, 0 | نقل النافذة لـ workspace رقم 1-10 |

## Mouse
| Keybind | الوظيفة |
|---------|---------|
| Super + Mouse Left | سحب النافذة |
| Super + Mouse Right | تغيير حجم النافذة |
| 3-finger swipe horizontal | التنقل بين الـ workspaces |

---
## ملاحظة عن Movies Widget (Super + P)
يفتح MovieWidget.qml — واجهة Quickshell لتتبع الأفلام/المسلسلات.
يتصل بـ TMDB API (مبني في Config.qml).
يدعم: بحث، تقييم، watchlist، تاريخ المشاهدة.

## ملاحظة عن Stewart
Stewart هو الـ mascot الـ animated في الـ dots.
يظهر في الـ TopBar أو كـ floating element.
يستخدم color temperature animation مع matugen palette.
لا يوجد keybind له — يشتغل تلقائياً.

## ملاحظة عن Serpantinum
Serpantinum ليس جزءاً من هذه الـ dots.
هو tool خارجي منفصل — إذا تبيه يتكامل، أضف exec له في autostart.conf.
