
Project Test Structure: 

/tests/
├── unit/                    # Fast, mocked tests
│   ├── MGMT-Functions.Tests.ps1
│   └── SystemAgent.Tests.ps1
├── integration/             # Real Windows environment tests
│   ├── FileOps.Tests.ps1
│   └── RegistryOps.Tests.ps1
├── mocks/                   # Mock Windows cmdlets
│   └── WindowsCmdlets.psm1
└── scenarios/               # Full end-to-end scenarios
    ├── FreshInstall.Tests.ps1
    └── Upgrade.Tests.ps1
