-- ملف إعدادات الشاشة monitors.lua
-- تفعيل الدقة القصوى (120Hz) مع عمق ألوان 10-bit، والـ HDR، والـ VRR تلقائياً

hl.monitor({
    output         = "eDP-1",
    mode           = "2560x1600@120",
    position       = "auto",
    scale          = 1,
    vrr            = 2,
})

