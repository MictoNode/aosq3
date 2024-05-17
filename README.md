1) Game = "0rVZYFxvfJpO__EfOz0_PUQ3GFE9kEaES0GkUDNXjvE"
2) .load bot.lua
3) Send({ Target = Game, Action = "Register" })
4) Send({ Target = Game, Action = "RequestTokens" })
5) Send({ Target = Game, Action = "Transfer", Recipient = Game, Quantity = "1000" })

once the message "ready to play" is displayed on the screen

Step 1: WAKING UP THE BOT

InAction = false

Send({Target = ao.id, Action = "Tick"})

Step 2: IN CASE OF NO ACTION

Check status of Bot:

InAction

If you get output = "true" then WAKE UP THE BOT i.e. do STEP 1 again

OTHER
1. To check last message
   
Inbox[#Inbox]

3. Check GAME STATE
   
LatestGameState

5. To check game's token balance
   
Send({ Target = Game, Action = "Balance" })

credit: MOTS Crypto
