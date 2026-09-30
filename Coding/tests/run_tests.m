function run_tests()
%RUN_TESTS 依次运行基础物理模型和事件逻辑检查，只依赖 MATLAB 本体。
names = {'testTwoBody','testJ2','testDensityDrag', ...
    'testThrustMass','testEventsModes','testWindowExit', ...
    'testSwitchTradeoff','testAtmosphereInput','testEngineeringBudget','testCaseResources', ...
    'testDeorbitSupervisor','testSupervisedPropagation'};
for k = 1:numel(names)
    % 测试失败时断言会中断流程；通过时打印测试函数名。
    feval(names{k});
    fprintf('PASS %s\n',names{k});
end
end
