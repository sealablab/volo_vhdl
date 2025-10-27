
Claude,
I have two interrelated goals that I think you can help me with at the same time: 

## S1) Migrate the 'models' directory to the following (new) repo.

https://github.com/sealablab/moku-models (already cloned into `./moku-models`)

I am terrible and managing git submodules and not great with pyroject.toml either - so I hope you can make all those changes for me 😅
## S2) Create an a skeleton moku-mcp  server 
https://github.com/sealablab/moku-models  (already cloned into `./moku-mcp`)

## To be clear: 
I __DONT__ want you to **implement** the MCP server. I want you to build the scaffolding (create a .pyproject file), etc as well as a MOKU_MCP_SERVER_IMPLEMENTATION_GUIDE.md to be acted upon later. 

That guide should **only** need to have knowledge about the `moku-models` and `moku` 1st party python library. 

You should however, choose the most compatible / equivalent tech-stack for it when you draft the plan. 

## Moku-mcp
MokuMCP: 
- DisoverMokus
- AttachMoku
- ReleaseMoku

These first three should be self-explanatory (see tools/moku-go.py)
The next two 
- PushConfig
- GetConfig
Refer to our @MokuConfig models obvi.

Ask follow up questions


