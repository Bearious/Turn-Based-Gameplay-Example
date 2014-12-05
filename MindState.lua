-----------------------------------------------------------------------------------
-- MindState.lua
-- Enrique Garc�a ( enrique.garcia.cota [AT] gmail [DOT] com ) - 19 Oct 2009
-- Based on Unrealscript's stateful objects
-----------------------------------------------------------------------------------

assert(Object~=nil and class~=nil, 'MiddleClass not detected. Please require it before using MindState')

--[[ StatefulObject declaration
  * Stateful classes have a list of states (accesible through class.states).
  * When a method is invoked on an instance of such classes, it is first looked up on the class current state (accesible through class.currentState)
  * If a method is not found on the current state, or if current state is nil, the method is looked up on the class itself
  * It is possible to change states by doing class:gotoState(stateName)
]]
StatefulObject = class('StatefulObject')

StatefulObject.states = {} -- the root state list

------------------------------------
-- PRIVATE ATTRIBUTES AND METHODS
------------------------------------
local _private = setmetatable({}, {__mode = "k"})   -- weak table storing private references

-- helper function used to call state callbacks (enterState, exitState, etc)
local _invokeCallback = function(self, state, callbackName, ... )
  if state==nil then return end
  local callback = state[callbackName]
  if(type(callback)=='function') then callback(self, ...) end
end

local _getStack=function(self)
  local stack = _private[self].stateStack
  assert(stack~=nil, "Could not find the stack for the object. Make sure you invoked super.initialize(self) on the constructor.")
  return stack
end

-- These methods will not be overriden by the states.
local _ignoredMethods = {
  states=1, initialize=1,
  gotoState=1, pushState=1, popState=1, popAllStates=1, getCurrentState=1, isInState=1,
  enterState=1, exitState=1, pushedState=1, poppedState=1, pausedState=1, continuedState=1,
  addState=1, subclass=1, includes=1
}

local _prevSubclass = StatefulObject.subclass -- previous way of creating subclasses (used to redefine subclass itself)

------------------------------------
-- INSTANCE METHODS
------------------------------------

--[[ constructor
  If your states need initialization, they can receive parameters via the initParameters parameter
  initParameters is a table with parameters used for initializing the states. These are needed mostly if
  your states have a custom superclass that needs parameters on their initialize() function.
]]
function StatefulObject:initialize(initParameters)
  super.initialize(self)
  initParameters = initParameters or {} --initialize to empty table if nil

  _private[self] = {
    states = {},
    stateStack = {}
  }

  for stateName,stateClass in pairs(self.class.states) do
    local state = stateClass:new(unpack(initParameters[stateName] or {}))
    state.name = stateName
    _private[self].states[stateName] = state
  end
end

--[[ Changes the current state.
  If the current state has a method called onExitState, it will be called, with the instance as a parameter.
  If the "next" state exists and has a method called onExitState, it will be called, with the instance as a parameter.
  use gotoState(nil) for setting states to nothing
  This method invokes the exitState and enterState functions if they exist on the current state
  Second parameter is optional. If true, the stack will be conserved. Otherwise, it will be popped.
]]
function StatefulObject:gotoState(newStateName, keepStack)
  assert(_private[self].states~=nil, "Attribute 'states' not detected. check that you called instance:gotoState and not instance.gotoState, and that you invoked super.initialize(self) in the constructor.")

  local prevState = self:getCurrentState()

  -- If we're trying to go to a state in which we already are, return (do nothing)
  if(prevState~=nil and prevState.name == newStateName) then return end

  local nextState
  if(newStateName~=nil) then
    nextState = _private[self].states[newStateName]
    assert(nextState~=nil, "State '" .. newStateName .. "' not found")
  end

  -- Either empty completely the stack, or just call the exitstate callback on current state
  if(keepStack~=true) then
    self:popAllStates()
  else
    _invokeCallback(self, prevState, 'exitState', newStateName )
  end

  -- replace the top of the stack with the new state
  local stack = _getStack(self)
  stack[math.max(#stack,1)] = nextState

  -- Invoke enterState on the new state. 2nd parameter is the name of the previous state, or nil
  _invokeCallback(self, nextState, 'enterState', prevState~=nil and prevState.name or nil)

end

--[[ Changes the current state, by pushing a new state on the stack.
  If the pushed state is already on the stack, this function does nothing.
  Invokes 'pausedState' on the previous state, if existing
  The new state is pushed on the top of the stack and then
  Invokes 'pushedState' and 'enterState' on the new state, if existing
]]
function StatefulObject:pushState(newStateName)
  assert(type(newStateName)=='string', "newStateName must be a string.")
  assert(_private[self].states~=nil, "Attribute 'states' not detected. check that you called instance:pushState and not instance.pushState, and that you invoked super.initialize(self) in the constructor.")

  local nextState = _private[self].states[newStateName]
  assert(nextState~=nil, "State '" .. newStateName .. "' not found")

  -- If we attempt to push a state and the state is already on return (do nothing)
  local stack = _getStack(self)
  for _,state in ipairs(stack) do
    if(state.name == newStateName) then return end
  end

  -- Invoke pausedState on the previous state
  _invokeCallback(self, self:getCurrentState(), 'pausedState')

  -- Do the push
  table.insert(stack, nextState)

  -- Invoke pushedState & enterState on the next state
  _invokeCallback(self, nextState, 'pushedState')
  _invokeCallback(self, nextState, 'enterState')

  return nextState
end

--[[ Removes a state from the state stack
   If a state name is given, it will attempt to remove it from the stack. If not found on the stack it will do nothing.
   If no state name is give, this pops the top state from the stack, if any. Otherwise it does nothing.
   Callbacks will be called when needed.
]]
function StatefulObject:popState(stateName)
  assert(_private[self].states~=nil, "Attribute 'states' not detected. check that you called instance:popState and not instance.popState, and that you invoked super.initialize(self) in the constructor.")

  -- Invoke exitstate & poppedState on the state being popped out
  local prevState = self:getCurrentState()
  _invokeCallback(self, prevState, 'exitState')
  _invokeCallback(self, prevState, 'poppedState')

  -- Do the pop
  local stack = _getStack(self)
  table.remove(stack, #stack)

  -- Invoke continuedState on the new state
  local newState = self:getCurrentState()
  _invokeCallback(self, newState, 'continuedState')

  return newState
end

--[[ Empties the state stack
   This function will invoke all the popState, exitState callbacks on all the states as they pop out.
]]
function StatefulObject:popAllStates()
  local state = self:popState()
  while(state~=nil) do state = self:popState() end
end

--[[ Returns the current state (top of the stack only)
  The current state's name can be obtained doing object:getCurrentState().name
]]
function StatefulObject:getCurrentState()
  local stack = _getStack(self)
  if #stack == 0 then return nil end
  return(stack[#stack])
end

--[[
  Returns true if the object is in the state named 'stateName'
  If second(optional) parameter is true, this method returns true if the state is on the stack instead
]]
function StatefulObject:isInState(stateName, testStateStack)
  local stack = _getStack(self)

  if(testStateStack==true) then
    for _,state in ipairs(stack) do
      if(state.name == stateName) then return true end
    end
  else --testStateStack==false
    local state = stack[#stack]
    if(state~=nil and state.name == stateName) then return true end
  end

  return false
end

------------------------------------
-- CLASS METHODS
------------------------------------


--[[ Adds a new state to the "states" class member.
  superState is optional. If nil, Object will be the parent class of the new state
  returns the newly created state
]]
function StatefulObject.addState(theClass, stateName, superState)
  assert(subclassOf(StatefulObject, theClass), "Use class:addState instead of class.addState")
  assert(theClass.states[stateName]==nil, "The class " .. theClass.name .. " already has a state called '" .. stateName)
  assert(type(stateName)=="string", "stateName must be a string")
  -- states are just regular classes. If superState is nil, this uses Object as superClass
  local state = class(stateName, superState)
  theClass.states[stateName] = state
  return state
end

--[[ Redefinition of Object:subclass
  Subclasses inherit all the states of their superclases, in a special way:
  If class A has a state called Sleeping and B = A.subClass('B'), then B.states.Sleeping is a subclass of A.states.Sleeping
  returns the newly created stateful class
]]
function StatefulObject.subclass(theClass, name)
  assert(theClass==StatefulObject or subclassOf(StatefulObject, theClass), "Use class:subclass instead of class.subclass")

  local theSubClass = _prevSubclass(theClass, name) --for now, theClass is just a regular subclass

  --the states of the subclass are subclasses of the superclass' states
  theSubClass.states = {}
  for stateName,state in pairs(theClass.states) do
    theSubClass:addState(stateName, state)
  end

  --look for instance methods on the state stack before looking them up on the class' dictionary
  local classDict = theSubClass.__classDict
  classDict.__index = function(instance, methodName)
    -- If the method isn't on the 'ignoredMethods' list, look through the stack to see if it is defined
    if(_ignoredMethods[methodName]~=1) then
      local stack = _private[instance].stateStack
      local method
      for i = #stack,1,-1 do -- reversal loop
        method = stack[i][methodName]
        if(method~=nil) then return method end
      end
    end
    --if ignored or not found, look on the class method
    return classDict[methodName]
  end

  return theSubClass
end


--[[ Include override for stateful classes.
     This is exactly like MiddleClass' include function, except that it module has a property called "states"
     then each member of that module.states is included on the StatefulObject class.
     If module.states has a state that doesn't exist on StatefulObject, a new state will be created.
]]
function StatefulObject.includes(theClass, module, ...)
  assert(subclassOf(StatefulObject, theClass), "Use class:includes instead of class.includes")
  for methodName,method in pairs(module) do
    if methodName ~="included" and methodName ~= "states" then
      theClass[methodName] = method
    end
  end
  if type(module.included)=="function" then module.included(theClass, ...) end
  if type(module.states)=="table" then
    for stateName,moduleState in pairs(module.states) do
      local state = theClass.states[stateName]
      if(state==nil) then state = theClass:addState(stateName) end
      state:includes(moduleState, ...)
    end
  end
end
