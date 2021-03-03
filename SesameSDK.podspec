Pod::Spec.new do |s|
    s.name                    = 'SesameSDK'
    s.version                 = '1.0.0'
    s.summary                 = 'SesameSDK summary.'
    s.homepage                = 'https://jp.candyhouse.co'

    s.author                  = { 'SesameSDK' => 'developers@candyhouse.co' }
    s.license                 = { :type => 'MIT', :file => 'LICENSE' }

    s.platform                = :ios
    s.source                  = { :http => 'https://sesame-ios-sdk-license.s3-ap-northeast-1.amazonaws.com/LICENSE.zip' }

    s.ios.deployment_target   = '10.0'
    s.ios.vendored_frameworks = 'sdk/SesameSDK.framework'
    s.dependency "AWSCore", '2.22.0'
    s.dependency "AWSAPIGateway", '2.22.0'
    s.dependency "AWSIoT", '2.22.0'
end
