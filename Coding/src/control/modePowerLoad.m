function watts = modePowerLoad(mode,thrustOn,q)
%MODEPOWERLOAD 唯一账本决定实际模式用电；占空比关闭时使用安全等待模式。
key = "SAFE";
if mode == "deploying", key = "S2";
elseif thrustOn, key = "S1";
elseif mode == "sail", key = "S3";
end
watts = q.modeLoads.peakLoad_W(q.modeLoads.mode==key);
assert(isscalar(watts) && isfinite(watts) && watts>=0);
end
