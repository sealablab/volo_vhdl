
  Clarifying Questions

  1. Integration Testing Scope: 
	I think we should try 'skipping to the end' on this one. What do you say we make a copy of the current 'probe-driver', -> 'probe-driver-en'

		- Then we try start re-creating it from the bottom up to use the new '-en' modules 
		- If that works fairly well then we will have combined them as much in test as we have in practice. 
		- Any bugs that fall out after that are more interesting.
  2. Migration Strategy: Do you want to:
	   See answer to #1
  3. Core Module Enhancement: When you mentioned "Apply unit hinting to core RTL modules" - are you thinking of:
    • Adding unit hinting to the existing core modules that use these datadef packages?
		- yes
	
  4. Priority: What's your main goal right now?
	   **Progress**: The previous datadefinitions were only mildly tested. I would prefer to migrate to the new '-en' module quickly so that bugs can be discovered during the next development cycle. (which will happen after this)
