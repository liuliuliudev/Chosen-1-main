function testJ2()
%TESTJ2 检查 J2 摄动量级及 J2 为零时的极限。
p = baseline_case(); x = initialOrbitState(p);
a = gravityJ2(x(1:3),p);
assert(norm(a) > 0 && norm(a) < norm(gravityTwoBody(x(1:3),p))*0.01);
p.earth.J2 = 0;
assert(norm(gravityJ2(x(1:3),p)) == 0);
end
