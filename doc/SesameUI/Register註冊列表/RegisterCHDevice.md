1.RegisterSesameDeviceViewController.swift
=>registerCHDevice()

2.CHSesame2Device+Register.swift
=> extension CHSesame2Device register()
=> getIRER()
=> onRegisterStage1()
=> onRegisterStage2()
=> registerCompleteHandler()

3.CHIoTManager.swift
＝> subscribeCHDeviceShadow()

4.Sesame2Store.swift
=>deletePropertyFor

5.RegisterSesameDeviceViewController.swift // UI loading View
=> ViewHelper.hideLoadingView()
=> dismissSelf() // 註冊列表 popup 頁

6.SesameDeviceListViewController.swift
=> getKeysFromCache()

7.RegisterSesameDeviceViewController.swift
=> CHUserAPIManager.shared.getSubId()

8.CHUserAPIManager+.swift
=> putCHUserKey()
