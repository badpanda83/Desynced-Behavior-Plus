local AttackUnit = {
  id = "attack_unit",
  name = "Attack Unit",
  description = "Orders a controlled unit to attack a target unit.",
  inputs = {
    { key = "self_unit", type = "unit", required = true },
    { key = "target_unit", type = "unit", required = true },
  },
}

function AttackUnit.validate(ctx)
  if not ctx then return false, "missing context" end
  if not ctx.self_unit then return false, "missing self_unit" end
  if not ctx.target_unit then return false, "missing target_unit" end
  return true
end

function AttackUnit.execute(ctx)
  local ok, err = AttackUnit.validate(ctx)
  if not ok then
    return false, err
  end

  -- Generic call pattern: adapt to Desynced API in your runtime.
  if ctx.command and ctx.command.attack then
    ctx.command.attack(ctx.self_unit, ctx.target_unit)
    return true
  end

  -- Fallback convention for alternate environments.
  if ctx.self_unit.attack then
    ctx.self_unit:attack(ctx.target_unit)
    return true
  end

  return false, "no compatible attack command found"
end

return AttackUnit
