local function RegisterVSKYTranq()
    if not _LAMBDAWEAPONS then return end

    _LAMBDAWEAPONS.m9tranqgun = {
        model = "models/lambdaplayers/weapons/w_pist_m9_tranq.mdl",
        origin = "Garry's Mod",
        prettyname = "Tranquilizer Gun (VSKY)",
        holdtype = "pistol",
        killicon = "weapon_m9tranqgun",
        keepdistance = 500,
        attackrange = 1500,
        dropentity = "weapon_m9tranqgun_vsky",
        islethal = true,
        OnAttack = function( self, wepent, target )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL )

            self:EmitSound( "lambdaplayers/weapons/tranqgun/tranqgun_fire.mp3", 75, 100, 1, CHAN_WEAPON )

            local pos = wepent:GetPos() + wepent:GetForward() * 10
            local fwd = (target:WorldSpaceCenter() - pos):GetNormalized()

            -- Вызов уникальной функции выстрела
            M9TranqGun_VSKY_FireDart( pos, fwd, self, wepent )

            return true
        end
    }
end

-- Попытка немедленной регистрации
RegisterVSKYTranq()

-- Резервный слушатель хука на случай, если таблицы инициализируются позже
hook.Add( "Initialize", "VSKY_Tranq_LambdaInitBack", function()
    RegisterVSKYTranq()
end )