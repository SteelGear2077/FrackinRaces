require "/scripts/vec2.lua"

function init()
  self.energyCostPerSecond = config.getParameter("energyCostPerSecond")
  self.active=false
  self.available = true
  self.species = world.entitySpecies(entity.id())
  self.timer = 0
  self.boostSpeed = 4
  idle()
  self.active=false
  self.available = true
end

function uninit()
  animator.stopAllSounds("activate")	
  status.clearPersistentEffects("glide")
  animator.setParticleEmitterActive("feathers", false)
end

function checkFood()
  if status.isResource("food") then
    self.foodValue = status.resource("food")		
  else
    self.foodValue = 15
  end
end

function boost(direction)
  self.boostVelocity = vec2.mul(vec2.norm(direction), self.boostSpeed)	
  if self.boostSpeed > 20 then  -- prevent super-rapid movement
    self.boostSpeed = 20
  end    
end

function checkMovement()
  if self.upVal or self.downVal or self.leftVal or self.rightVal then
    status.setPersistentEffects("glide", {
      {stat = "gliding", amount = 0},
      {stat = "fallDamageResistance", effectiveMultiplier = 1.65}
    }) 
  else 
    status.setPersistentEffects("glide", {
      {stat = "gliding", amount = 1},
      {stat = "fallDamageResistance", effectiveMultiplier = 1.65}
    }) 
  end
end

function update(args)
  checkFood()

  if not self.specialLast and args.moves["special1"] then 
    attemptActivation() 
  end

  self.specialLast = args.moves["special1"]
  self.upVal = args.moves["up"]
  self.downVal = args.moves["down"]
  self.leftVal = args.moves["right"]
  self.rightVal = args.moves["left"]  

  
  if not args.moves["special1"] then 
    self.forceTimer = nil 
  end
  
  if self.active and status.overConsumeResource("energy", 0.01) then
    if not mcontroller.zeroG() and not mcontroller.liquidMovement() then 
	  mcontroller.controlParameters(config.getParameter("fallingParameters"))
	  mcontroller.setYVelocity(math.max(mcontroller.yVelocity(), config.getParameter("maxFallSpeed")))  
	  
	  local direction = {0, 0}
	  if args.moves["up"] then direction[2] = direction[2] + 1 end     
	  if args.moves["down"] then direction[2] = direction[2] - 1 end                    
	  if args.moves["right"] then direction[1] = direction[1] + 1 end  
	  if args.moves["left"] then direction[1] = direction[1] - 1 end 
          self.boostSpeed = self.boostSpeed + args.dt
	  boost(direction) 
	  if vec2.eq(direction, {0, 0}) then 
	    direction = {0, 0} 		    
	  end
	  mcontroller.controlApproachVelocity(self.boostVelocity, 30)
	  
          checkMovement()
	  if self.foodValue > 15 then
	    status.addEphemeralEffects{{effect = "foodcost", duration = 0.1}} 
	  else
	    status.overConsumeResource("energy", config.getParameter("energyCostPerSecond"),1)
	  end	
    end  
    checkForceDeactivate(args.dt)
  end
end

function attemptActivation()
  if not self.active then
    activate()
  elseif self.active then
      deactivate()
      if not self.forceTimer then
        self.forceTimer = 0
      end
  end
end

function checkForceDeactivate(dt)
  if self.forceTimer then
    self.forceTimer = self.forceTimer + dt
    if self.forceTimer >= self.forceDeactivateTime then
      deactivate()
      self.forceTimer = nil       
    else
      attemptActivation()
    end
    return true
  else
    return false
  end
end

function activate()
  if not self.active then
        animator.playSound("activate") 	
  else
        status.clearPersistentEffects("glide")      
        deactivate()
  end
  self.active = true
end

function deactivate()
  if self.active then
    status.clearPersistentEffects("glide") 
    animator.setParticleEmitterActive("feathers", false)
    self.boostSpeed = 4
  end
  self.active = false  
end


function idle()
    animator.stopAllSounds("activate")	
    self.boostSpeed = 4
end