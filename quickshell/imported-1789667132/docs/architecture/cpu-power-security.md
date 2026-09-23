# CPU 功耗读取边界

RAPL 和其他 CPU 功耗指标属于独立的 `keytop` 能力。Clavis Shell 只消费
`keytop value stream` 的结果，不请求 sudo、不安装 capability，也不管理权限 helper。

```bash
keytop value cpu --format json
keytop value snapshot --format json --modules cpu,system,memory
```

不可读的 powercap 接口应报告 unsupported 或 permission denied，同时继续提供其他
系统指标。任何需要系统权限的打包集成都应由 keytop 的发行版包单独设计和审核。
