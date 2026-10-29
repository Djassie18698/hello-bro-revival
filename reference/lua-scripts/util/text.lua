-- This file is created by tools.

module( "text" )

text_config = {
[8000] = {id=8000,
description="Parameter error"
},

[8001] = {id=8001,
description="Parameter error"
},

[8002] = {id=8002,
description="Parameter error"
},

[50000] = {id=50000,
description="Data doesnt exist"
},

[9998] = {id=9998,
description="Incorrect method of submission"
},

[9999] = {id=9999,
description="Invalid command"
},

[10002] = {id=10002,
description="This account name has already been registered"
},

[10003] = {id=10003,
description="This account doesnt exist"
},

[10004] = {id=10004,
description="Incorrect password"
},

[10005] = {id=10005,
description="Data not found, unable to submit"
},

[10006] = {id=10006,
description="You have insufficient gold!"
},

[10007] = {id=10007,
description="You have insufficient energy!"
},

[10008] = {id=10008,
description="You have insufficient silver!"
},

[10009] = {id=10009,
description="Data search failed"
},

[10010] = {id=10010,
description="Data submission failed"
},

[10011] = {id=10011,
description="Already initialised"
},

[10012] = {id=10012,
description="Insufficient ID"
},

[10013] = {id=10013,
description="Name list has been exhausted, please give a name yourself!"
},

[10014] = {id=10014,
description="You already have an account on this server, unable to register again!"
},

[10016] = {id=10016,
description="Illegal platform number or region number!"
},

[10015] = {id=10015,
description="Its not the right time, or you have already had ramen."
},

[10017] = {id=10017,
description="Words entered includes sensitive characters"
},

[20000] = {id=20000,
description="No data in bagpack"
},

[20001] = {id=20001,
description="Card to be upgraded is not in bagpack"
},

[20002] = {id=20002,
description="Some cards to be swallowed are not in the bagpack"
},

[20003] = {id=20003,
description="Some cards are of a different type than those to be swallowed"
},

[20004] = {id=20004,
description="Bagpack is full"
},

[20005] = {id=20005,
description="Incorrect state of swallowed card"
},

[20006] = {id=20006,
description="Card is not in bagpack"
},

[20007] = {id=20007,
description="Insufficient cards"
},

[30000] = {id=30000,
description="Incorrect team line-up"
},

[30001] = {id=30001,
description="Card needed to exchange is not in the bag"
},

[30002] = {id=30002,
description="Card to be exchanged has a wrong state"
},

[30003] = {id=30003,
description="Card to exchange has a wrong state"
},

[30004] = {id=30004,
description="No additional card slot"
},

[30005] = {id=30005,
description="Only a shinobi card can open up a new card slot"
},

[30006] = {id=30006,
description="Unable to deactivate shinobi card"
},

[30007] = {id=30007,
description="Unable to add card, as there is a new card in play"
},

[30008] = {id=30008,
description="New card type is different from the position played"
},

[30009] = {id=30009,
description="Illegal command"
},

[30010] = {id=30010,
description="Card that needs to be uninstalled does not exist"
},

[30011] = {id=30011,
description="No such data in the team"
},

[30012] = {id=30012,
description="Team not found"
},

[30013] = {id=30013,
description="Requires Lv.50"
},

[30014] = {id=30014,
description="The card is in use"
},

[30015] = {id=30015,
description="No team data is found"
},

[30016] = {id=30016,
description="The card isnt in the team"
},

[40001] = {id=40001,
description="Unable to get World Experience data"
},

[40002] = {id=40002,
description="World Experience data is incompatible with background"
},

[40003] = {id=40003,
description="Unable to retrieve information for this round"
},

[40004] = {id=40004,
description="Insufficient energy to proceed with training"
},

[40005] = {id=40005,
description="Unable to retrieve NPC information"
},

[40006] = {id=40006,
description="You have reached the end of the world"
},

[40007] = {id=40007,
description="The chapters you need to train are not open yet"
},

[40008] = {id=40008,
description="You have used up all available retreats this round"
},

[40009] = {id=40009,
description="Unable to retreat at the end of the chapter"
},

[40010] = {id=40010,
description="No such chapter"
},

[40011] = {id=40011,
description="Unable to find chapter that is reset"
},

[40012] = {id=40012,
description="didnt reach clearance"
},

[80001] = {id=80001,
description="didnt pick up dropped shinobi card"
},

[80002] = {id=80002,
description="Returned many shinobi cards"
},

[80003] = {id=80003,
description="Have not reached time for free card draw"
},

[80004] = {id=80004,
description="Failed to put card drawn in users bagpack"
},

[80005] = {id=80005,
description="You have reached the daily limit of free card draw"
},

[90001] = {id=90001,
description="Insufficient fragments, unable to synthesise seal"
},

[90002] = {id=90002,
description="Illegal ID during synthesis of seal"
},

[90003] = {id=90003,
description="In synthesising!"
},

[90004] = {id=90004,
description="Synthesis not started yet"
},

[90005] = {id=90005,
description="Friends Son"
},

[90006] = {id=90006,
description="Plundered during synthesis, insufficient fragments, synthesis failed"
},

[100001] = {id=100001,
description="Target dont have the fragment you wish to plunder"
},

[100002] = {id=100002,
description="Incompatible levels"
},

[110001] = {id=110001,
description="Illegal bid"
},

[110002] = {id=110002,
description="Content of bid doesnt exist"
},

[11003] = {id=11003,
description="Failed settings as read"
},

[120001] = {id=120001,
description="You have reached the maximum number of friends"
},

[120002] = {id=120002,
description="This player is already your friend"
},

[120003] = {id=120003,
description="You have reached the maximum number"
},

[120004] = {id=120004,
description="Already processed"
},

[120005] = {id=120005,
description="Its not an operation of friend request notification"
},

[130001] = {id=130001,
description="Insufficient items"
},

[130003] = {id=130003,
description="You have reached the daily limit for using this item"
},

[140001] = {id=140001,
description="Progress does not match"
},

[140002] = {id=140002,
description="No further levels"
},

[150001] = {id=150001,
description="Unable to start a war, already reached the limit"
},

[150002] = {id=150002,
description="Failed to steal position, others are currently fighting for this position"
},

[150003] = {id=150003,
description="In process of declaring war, unable to declare more"
},

[150004] = {id=150004,
description="The country you are in has not yet started a war"
},

[150005] = {id=150005,
description="No users to battle currently"
},

[150006] = {id=150006,
description="War not open yet"
},

[150007] = {id=150007,
description="You have no more resurrection counts, please purchase more"
},

[150008] = {id=150008,
description="Invalid Exchange ID"
},

[150009] = {id=150009,
description="This gifts ID is not an Exchange ID"
},

[150010] = {id=150010,
description="Insufficient Merit points"
},

[150011] = {id=150011,
description="You have claimed this gift"
},

[150012] = {id=150012,
description="Previous war is not open yet"
},

[150013] = {id=150013,
description="You didnt win the previous war, unable to claim"
},

[150014] = {id=150014,
description="You have no authority to start a war"
},

[150015] = {id=150015,
description="Unable to declare war with your own country"
},

[150016] = {id=150016,
description="You are currently in a war, unable to declare war"
},

[150017] = {id=150017,
description="You are currently in a war, or 1 hour before war, unable to check the results"
},

[150018] = {id=150018,
description="You didnt participate in the previous war, unable to show results"
},

[150019] = {id=150019,
description="You are not qualified to receive the officers gift pack"
},

[150020] = {id=150020,
description="You have already retrieved today, unable to claim again"
},

[150021] = {id=150021,
description="Unable to steal position from yourself"
},

[150022] = {id=150022,
description="Claim gift pack after being in position after 24 hours"
},

[150023] = {id=150023,
description="Our morale is 0, unable to participate in any more attacks!"
},

[160001] = {id=160001,
description="Someone is plundering"
},

[160002] = {id=160002,
description="Unable to attack, please check CD or chances of attacks"
},

[160003] = {id=160003,
description="Unable to fight yourself"
},

[160004] = {id=160004,
description="Target is under attack, please try again later"
},

[160005] = {id=160005,
description="Unable to challenge players with a lower level than yourself"
},

[160006] = {id=160006,
description="Time to claim gift has not arrived"
},

[160007] = {id=160007,
description="You have not met requirements for claiming"
},

[160008] = {id=160008,
description="Level of challenge is out of range"
},

[160009] = {id=160009,
description="You can attack without resetting CD, dont waste gold"
},

[160010] = {id=160010,
description="Number of attacks for the day has been used, reset failed!"
},

[160011] = {id=160011,
description="Total exchange has reached its limits"
},

[160012] = {id=160012,
description="Todays exchange has reached its limits"
},

[160013] = {id=160013,
description="You have already claimed the reward for today"
},

[160014] = {id=160014,
description="Time to claim reward has not arrived"
},

[160015] = {id=160015,
description="Time to claim reward has past"
},

[160016] = {id=160016,
description="You are unranked currently"
},

[160017] = {id=160017,
description="Unable to challenge as it is claiming time now"
},

[160018] = {id=160018,
description="Unable to claim rewards during a fight"
},

[170001] = {id=170001,
description="Event claimed has expired"
},

[170002] = {id=170002,
description="Currently not qualified to claim"
},

[170003] = {id=170003,
description="Previous Monthly Card has not claimed, currently unable to buy similar products"
},

[170004] = {id=170004,
description="Already claimed."
},

[170005] = {id=170005,
description="You have already claimed today, please come again tomorrow."
},

[170006] = {id=170006,
description="Event does not exist"
},

[170007] = {id=170007,
description="You have already claimed, unable to claim again"
},

[170008] = {id=170008,
description="This event does not exist"
},

[180001] = {id=180001,
description="In cd time"
},

[180002] = {id=180002,
description="You have no more chances today"
},

[180003] = {id=180003,
description="You are already a defender"
},

[180004] = {id=180004,
description="Target country cannot be your own country"
},

[180005] = {id=180005,
description="No fragments available to plunder"
},

[180006] = {id=180006,
description="No need to clear cd"
},

[180007] = {id=180007,
description="No remaining attacks left, invalid clearance of cd"
},

[180007] = {id=180007,
description="No rewards available to claim"
},

[190008] = {id=190008,
description="You have reached the highest possible level"
},

[190009] = {id=190009,
description="Wrong number of sage stones"
},

[190010] = {id=190010,
description="Unable to strengthen this card type"
},

[210000] = {id=210000,
description="No existing app id"
},

[210001] = {id=210001,
description="Secret key error"
},

[210002] = {id=210002,
description="Session error"
},

[210004] = {id=210004,
description="Unable to find settings for this platform"
},

[210005] = {id=210005,
description="Account verification failed"
},

[210006] = {id=210006,
description="Wrong platform id"
},

[210007] = {id=210007,
description="Wrong region"
},

[210008] = {id=210008,
description="Not yet open for registration"
},

[210009] = {id=210009,
description="Authentication parameter error"
},

[210010] = {id=210010,
description="Login session expired"
},

[210011] = {id=210011,
description="Code verification failed"
},

[210012] = {id=210012,
description="Please register an account to save current game data before logging in to other accounts."
},

[210014] = {id=210014,
description="Account locked, please contact administrator"
},

[220000] = {id=220000,
description="No information about this platform"
},

[230001] = {id=230001,
description="Unable to find platform number"
},

[230002] = {id=230002,
description="Unable to find region number"
},

[240000] = {id=240000,
description="Hey man, you have bullied this guy 5 times today, come again tomorrow."
},

[250001] = {id=250001,
description="Delivery failed, wrong order number"
},

[250002] = {id=250002,
description="Order failed, please dont repeat an order"
},

[250003] = {id=250003,
description="You have already purchased a monthly card"
},

[250004] = {id=250004,
description="Illegal product ID"
},

[250005] = {id=250005,
description="You are not qualified to claim the first charge gift pack"
},

[250006] = {id=250006,
description="Delivery incomplete"
},

[250007] = {id=250007,
description="Unable to find order number"
},

[250008] = {id=250008,
description="You are not authorised to claim the first charge gift pack"
},

[250009] = {id=250009,
description="Monthly card orders cannot be repeated within 10 minutes"
},

[270000] = {id=270000,
description="The big wheel is closed"
},

[270001] = {id=270001,
description="The big wheel has expired"
},

[270002] = {id=270002,
description="Inconsistent big wheel id, it should be a different round"
},

[270003] = {id=270003,
description="Insufficient gold"
},

[270004] = {id=270004,
description="You bagpack is full"
},

[270005] = {id=270005,
description="Please claim your ranking gift 3 hours after event ends"
},

[270006] = {id=270006,
description="Big wheel gift has been claimed"
},

[270007] = {id=270007,
description="Insufficient points, exchange failed"
},

[280001] = {id=280001,
description="Invitation code has already been used"
},

[280002] = {id=280002,
description="Operation is too frequent"
},

[280003] = {id=280003,
description="You have reached the maximum number of entries for the day, come again tomorrow"
},

[280004] = {id=280004,
description="Invitation code does not exist"
},

[280005] = {id=280005,
description="You have already claimed this gift type"
},

[20006] = {id=20006,
description="Card does not exist"
},

[20005] = {id=20005,
description="Card is in play, unable to dismantle"
},

[290000] = {id=290000,
description="This card type is not supported"
},

[289999] = {id=289999,
description="Unable to dismantle low level cards"
},

[290001] = {id=290001,
description="Shinobi card has not reached the highest level"
},

[290002] = {id=290002,
description="Insufficient cards of the same type"
},

[290003] = {id=290003,
description="Insufficient reincarnation pills"
},

[290004] = {id=290004,
description="Wrong reincarnation card type"
},

[290005] = {id=290005,
description="Wrong reincarnation level"
},

[290006] = {id=290006,
description="Please choose the same type of card"
},

[300001] = {id=300001,
description="Wrong group number"
},

[300002] = {id=300002,
description="Wrong platform"
},

[300003] = {id=300003,
description="Wrong region number"
},

[300004] = {id=300004,
description="Server is full, please choose another server"
},

[300005] = {id=300005,
description="Server is full, please choose another server"
},

[300006] = {id=300006,
description="Server is full, please choose another server"
},

[290101] = {id=290101,
description="You have reached the daily limit for purchase"
},

[290102] = {id=290102,
description="Insufficient VIP level, unable to purchase this gift"
},

[290103] = {id=290103,
description="Insufficient gold"
},

[290104] = {id=290104,
description="You have already purchased this gift today"
},

[290200] = {id=290200,
description="Country to be targeted does not exist"
},

[290201] = {id=290201,
description="Unable to change countries as you are currently in war or 1 hour before war"
},

[290202] = {id=290202,
description="Unable to change to your own country"
},

[290203] = {id=290203,
description="Wrong card type"
},

[290300] = {id=290300,
description="Insufficient gold for scratch card"
},

[310001] = {id=310001,
description="Wrong collection id"
},

[310002] = {id=310002,
description="You have reached the limit for exchange"
},

[310003] = {id=310003,
description="Requirements not met"
},

[240002] = {id=240002,
description="Insufficient spar value, unable to spar"
},

[310004] = {id=310004,
description="You have already activated automatic battle, you dont need to purchase, please dont waste gold"
},

[312000] = {id=312000,
description="This event has ended"
},

[312001] = {id=312001,
description="Not qualified to claim"
},

[312002] = {id=312002,
description="It is not yet time to claim"
},

[312003] = {id=312003,
description="Time for claiming has past"
},

[313000] = {id=313000,
description="This event has ended"
},

[313001] = {id=313001,
description="You are not the first to claim reward"
},

[313002] = {id=313002,
description="It is not yet time to claim reward"
},

[313003] = {id=313003,
description="Time for reward claiming has past"
},

[313004] = {id=313004,
description="You have no more blood to continue challenging"
},

[313005] = {id=313005,
description="Randomization failed"
},

[313006] = {id=313006,
description="Incompatible with current NPCs progress"
},

[313007] = {id=313007,
description="It is not time for reward claiming, unable to claim"
},

[313008] = {id=313008,
description="No rewards available for exchange"
},

[313009] = {id=313009,
description="Sorry, insufficient luck"
},

[313010] = {id=313010,
description="Incorrect reward type"
},

[313011] = {id=313011,
description="Failed to retrieve ranking data"
},

[313012] = {id=313012,
description="Error in increasing ranking"
},

[313013] = {id=313013,
description="You are not authorised to claim this reward"
},

[313014] = {id=313014,
description="You have already claimed this reward"
},

[313015] = {id=313015,
description="Your HP is at its maximum value"
},

[315001] = {id=315001,
description="Event closed"
},

[315002] = {id=315002,
description="Boss has already been defeated"
},

[315003] = {id=315003,
description="Boss is not dead yet or has not ended"
},

[315004] = {id=315004,
description="You have already claimed your reputation reward"
},

[315005] = {id=315005,
description="Event is in progress, please claim after event ends"
},

[315006] = {id=315006,
description="You have already claimed this reward"
},

[315007] = {id=315007,
description="You have not met requirements for claiming"
},

[315008] = {id=315008,
description="Insufficient reputation points"
},

[315009] = {id=315009,
description="Previous event has closed, unable to claim"
},

[316009] = {id=316009,
description="You have reached the maximum number of retreats per day for this chapter."
},

[317001] = {id=317001,
description="Tools dont have double increase"
},

[317002] = {id=317002,
description="Tool effect does not exist"
},

[318001] = {id=318001,
description="Restricted frequency"
},

[319001] = {id=319001,
description="It is sold out"
},

[319002] = {id=319002,
description="Product not found"
},

[319003] = {id=319003,
description="Event has ended"
},

[320001] = {id=320001,
description="Event has ended"
},

[320002] = {id=320002,
description="Insufficient flowers"
},

[321001] = {id=321001,
description="Only shinobi cards can be nurtured"
},

[321002] = {id=321002,
description="Insufficient Super Ninja pills"
},

[321003] = {id=321003,
description="Incorrect regional settings"
},

[321004] = {id=321004,
description="Requires more potential points"
},

[323001] = {id=323001,
description="Registration in progress"
},

[323002] = {id=323002,
description="Battle has ended"
},

[323003] = {id=323003,
description="You are not qualified to fight"
},

[323004] = {id=323004,
description="Not open"
},

[323005] = {id=323005,
description="It is not time for registration"
},

[323006] = {id=323006,
description="It is not time for battle"
},

[323007] = {id=323007,
description="You have reached the maximum number of morale boosts"
},

[323008] = {id=323008,
description="Insufficient points"
},

[323009] = {id=323009,
description="You are already participating, no need to register"
},

[323010] = {id=323010,
description="Incorrect position id of challenge"
},

[323011] = {id=323011,
description="You are unable to pk yourself"
},

[323012] = {id=323012,
description="Someone is already fighting in that position"
},

[323013] = {id=323013,
description="Your position is already changed"
},

[323014] = {id=323014,
description="Battle has not yet ended"
},

[323015] = {id=323015,
description="Reward has already been claimed"
},

[323016] = {id=323016,
description="You are not qualified to claim the reward"
},

[323017] = {id=323017,
description="Page number is not within acceptable range"
},

[323018] = {id=323018,
description="This periods battle has not yet started"
},

[325000] = {id=325000,
description="Unable to refresh"
},

[325001] = {id=325001,
description="Product does not exist"
},

[325002] = {id=325002,
description="Product has already been purchased"
},

[325003] = {id=325003,
description="Incorrect payment method"
},

[325004] = {id=325004,
description="Insufficient soul"
},

[325005] = {id=325005,
description="Card level is too low"
},

[325006] = {id=325006,
description="You are only able to refresh 150 times per day, please come again tomorrow!"
},

[324000] = {id=324000,
description="Insufficient fragments"
},

[324001] = {id=324001,
description="Fragment does not exist"
},

[324002] = {id=324002,
description="Fragment bag is already full"
},

[325000] = {id=325000,
description="No recruitment order"
},

[330000] = {id=330000,
description="No more chance for level clearance!"
},

[330001] = {id=330001,
description="Youve cleared the level!"
},

[340000] = {id=340000,
description="No task in the list"
},

[340001] = {id=340001,
description="No reward in the list"
},

[340002] = {id=340002,
description="Insufficient points for reward"
},

[340003] = {id=340003,
description="Reward is claimed"
},

[350000] = {id=350000,
description="20:00 - 20:30 is time to run lottery. Please bet after 20:30!"
},

[350001] = {id=350001,
description="Youve bet enough. VIP can bet more!"
},

[350002] = {id=350002,
description="You got no reward. Try again!"
},

[350003] = {id=350003,
description="You have already claimed the reward"
},

[350004] = {id=350004,
description="20:00 - 20:30 is time to run lottery. Claim reward after running!"
},

[350005] = {id=350005,
description="You can only join the event after reaching Lv.50! Come then!"
},

[520001] = {id=520001,
description="Please download the full version to activate this function"
},

[140003] = {id=140003,
description="Insufficient achievements"
},

[140004] = {id=140004,
description="Reward has already been claimed, unable to claim again"
},

[322008] = {id=322008,
description="Energy is already full, no need for increase"
},

[326700] = {id=326700,
description="Date is not within target range"
},

[326701] = {id=326701,
description="Reward has already been claimed"
},

[326702] = {id=326702,
description="You are not qualified to claim"
},

[290105] = {id=290105,
description="You have already purchased this gift pack"
},

[325007] = {id=325007,
description="Reached the maximum chances to open the box"
},

[326000] = {id=326000,
description="Event ends"
},

[326001] = {id=326001,
description="Failed to read super ninja settings"
},

[326002] = {id=326002,
description="Failed to retrieve super ninja ranking list"
},

[326003] = {id=326003,
description="Failed to retrieve super ninja players ranking"
},

[326004] = {id=326004,
description="Not free time"
},

[326005] = {id=326005,
description="Error in increasing ranking"
},

[326006] = {id=326006,
description="Event is not in reward claiming period"
},

[326007] = {id=326007,
description="No reward to be claimed"
},

[326008] = {id=326008,
description="Reward already claimed"
},

[326700] = {id=326700,
description="Date is not within target range"
},

[326701] = {id=326701,
description="Reward has already been claimed"
},

[326702] = {id=326702,
description="You are not qualified to claim"
},

[327000] = {id=327000,
description="This type has already reached its top"
},

[327001] = {id=327001,
description="Time is in cd, cannot attack"
},

[327002] = {id=327002,
description="You can attack not, dont waste gold clearing cd"
},

[327003] = {id=327003,
description="You didnt join the previous world boss event, cannot claim the reward"
},

[327004] = {id=327004,
description="You can increase attacking power every morning at 8am."
},

[327005] = {id=327005,
description="Boss is dead, there is no use in increasing"
},

[328000] = {id=328000,
description="Fund purchased"
},

[328001] = {id=328001,
description="Failed to read configuration table"
},

[328002] = {id=328002,
description="No rewards to claim"
},

[328003] = {id=328003,
description="Rewards already claimed"
},

[328004] = {id=328004,
description="Reward obtained notification failed"
},

[328005] = {id=328005,
description="Data refresh failed"
},

[328006] = {id=328006,
description="You have not purchased growth funds"
},

[328007] = {id=328007,
description="Event has not started"
},

[328008] = {id=328008,
description="vip等级不足"
},

[329000] = {id=329000,
description="Failed to obtain data of a countrys boundary monument"
},

[329001] = {id=329001,
description="Failed to set data of a countrys boundary monument"
},

[329002] = {id=329002,
description="Failed to obtain boundary monument data"
},

[329003] = {id=329003,
description="Failed to set boundary monument data"
},

[329004] = {id=329004,
description="Failed to obtain configuration"
},

[329005] = {id=329005,
description="War at border  doesnt start"
},

[329006] = {id=329006,
description="War at border has ended"
},

[329007] = {id=329007,
description="Your duel points is insufficient"
},

[329008] = {id=329008,
description="You have already claimed the reward"
},

[329009] = {id=329009,
description="You have already received the boundary monument time bonus"
},

[329010] = {id=329010,
description="You have already received the top 3 rewards of the border"
},

[329011] = {id=329011,
description="Your ranking has no reward"
},

[329012] = {id=329012,
description="You are taunting this country"
},

[329013] = {id=329013,
description="You are wandering in this country"
},

[329014] = {id=329014,
description="Reward obtained notification failed"
},

[329015] = {id=329015,
description="Failed to set notifications for rewards"
},

[329016] = {id=329016,
description="Boundary monument temporarily unable to be attacked"
},

[329017] = {id=329017,
description="Boundary monument has been destroyed"
},

[329018] = {id=329018,
description="Insufficient gold"
},

[329019] = {id=329019,
description="Insufficient Silver"
},

[329020] = {id=329020,
description="Change target to attack when there is a reward"
},

[329021] = {id=329021,
description="Player is currently being removed by someone"
},

[329022] = {id=329022,
description="Enemy is not taunting or wandering, unable to remove"
},

[351001] = {id=351001,
description="累计积分不足，无法领取排行第一奖励, 领取第二名的奖励。"
},

[351002] = {id=351002,
description="累计积分不足，无法领取排行奖励，领取第二名的奖励。"
},

[351003] = {id=351003,
description="累计积分不足，无法领取排行奖励，领取第二名的奖励。"
},

[360000] = {id=360000,
description="道具不足"
},

[360001] = {id=360001,
description="该忍者不支持神卡合成"
},

[370001] = {id=370001,
description="全部奖励都已经领取"
},

[380001] = {id=380001,
description="本日拉面转换次数已经用完，请明天再来！"
},

[380002] = {id=380002,
description="您的拉面数量不足！"
},

[380003] = {id=380003,
description="未达到转换的等级限制！"
},

[310005] = {id=310005,
description="活动已经结束"
},

[1] = {id=1,
description="Successfully purchased"
},

[2] = {id=2,
description="Used successfully, obtained %d silver"
},

[3] = {id=3,
description="Used successfully, you have recovered %d energy points"
},

[4] = {id=4,
description="Used successfully, you have recovered %d%% duel points"
},

[5] = {id=5,
description="Your energy level is full"
},

[6] = {id=6,
description="Your Duel Points is full"
},

[7] = {id=7,
description="You have insufficient Tool"
},

[8] = {id=8,
description="You have insufficient gold, please recharge"
},

[9] = {id=9,
description="You have insufficient silver, you can use gold to purchase in the mall"
},

[10] = {id=10,
description="Land of Wind"
},

[11] = {id=11,
description="Land of Thunder"
},

[12] = {id=12,
description="Land of Water"
},

[13] = {id=13,
description="Land of Fire"
},

[14] = {id=14,
description="Land of Earth"
},

[15] = {id=15,
description="Free after %2d days %2d hours"
},

[16] = {id=16,
description="Free after %02d:%02d"
},

[17] = {id=17,
description="You can claim %d times today"
},

[18] = {id=18,
description="Please choose a country to declare war with"
},

[19] = {id=19,
description="You are already in this position"
},

[20] = {id=20,
description="Friend request"
},

[21] = {id=21,
description="Friend notification"
},

[22] = {id=22,
description=[[Player %s wishes to be your friend. 
 Message: %s]]
},

[23] = {id=23,
description="Player %s wishes to be your friend. Message: %s"
},

[24] = {id=24,
description="Player %s has accepted your friend request."
},

[25] = {id=25,
description="Player %s has rejected your friend request."
},

[26] = {id=26,
description="Spar"
},

[27] = {id=27,
description="Plunder"
},

[28] = {id=28,
description="Player %s has defeated you in the spar, you lost %d silver."
},

[29] = {id=29,
description="Player %s has been defeated by you in the spar, you won %d silver."
},

[30] = {id=30,
description="Player %s won you, and stole %s from your hands."
},

[31] = {id=31,
description="Player %s won you, but failed to steal %s from your hands."
},

[32] = {id=32,
description="Player %s wishes to steal %s from your hands, but you have defeated player %s."
},

[33] = {id=33,
description="You win"
},

[34] = {id=34,
description="You lose"
},

[35] = {id=35,
description="System notification"
},

[36] = {id=36,
description="You have declared a war with %s, war starts at: %s"
},

[37] = {id=37,
description="%s restrains %s"
},

[38] = {id=38,
description="War has begun, please join the war!!"
},

[39] = {id=39,
description="Competing for this position requires gold: %d"
},

[40] = {id=40,
description="Shinobi Card"
},

[41] = {id=41,
description="Equipping card"
},

[42] = {id=42,
description="Weapon Card"
},

[43] = {id=43,
description="Trinket Card"
},

[44] = {id=44,
description="Ninjutsu card"
},

[45] = {id=45,
description="Seal fragments"
},

[46] = {id=46,
description="Sealing Card"
},

[47] = {id=47,
description="Insufficient merit, please try again later"
},

[48] = {id=48,
description="It is never too late for revenge, please come back to avenge after you grow stronger."
},

[49] = {id=49,
description="Congratulations on showing your power, you have obtained the seal of Tailed Beast: %s success!"
},

[50] = {id=50,
description="Unlucky! Although you have won, your opponent ran away with %s!"
},

[51] = {id=51,
description="It is never too late for revenge, please come back to avenge after you grow stronger."
},

[52] = {id=52,
description="You are the better one, you have defeated your opponent and obtained your opponents %s: %s"
},

[53] = {id=53,
description="Reward for passing this level:"
},

[54] = {id=54,
description="Defeat is common, come back again after you have grown stronger, young shinobi!"
},

[55] = {id=55,
description="(By equipping shinobi, equipments, and ninjitsu, you can increase in power. This can also be done through increasing in level and strengthening these cards.)"
},

[56] = {id=56,
description="Congratulations, you have defeated a strong enemy, level up!"
},

[57] = {id=57,
description="Defeat is common, come back again after you have grown stronger, young shinobi!"
},

[58] = {id=58,
description="You are the better one, you have defeated your opponent from the land of fire: %s, and protected your countrys honour. Kill count in this war: %d"
},

[59] = {id=59,
description="Defeat is common, You are unable to defeat player Konohamaru from the Land of Fire. Please try again! Resurrection counts left in this war: %d"
},

[60] = {id=60,
description="War Achievements: %d (War achievements can be exchanged for treasure chests, and you will have the chance to win the Sage of the Six Paths card.)"
},

[61] = {id=61,
description="You are incredibly brave, and have defeated %ss defender of the treasure, and have obtained a national treasure."
},

[62] = {id=62,
description="Defeat is common, you have been defeated by %ss defender of the treasure: %s. You have not obtained the national treasure, please try harder."
},

[63] = {id=63,
description="%d pieces of national treasure (Please return to your national treasure interface, turn it in, and receive 5000 silver!)"
},

[64] = {id=64,
description="Ninjitsu damage is affected by Chakra. Ninjitsu damage is doubled with every 500 Chakra points."
},

[65] = {id=65,
description="Free recruitment"
},

[66] = {id=66,
description="Six-Star Orange Card"
},

[67] = {id=67,
description="Five-Star Purple Card"
},

[68] = {id=68,
description="Four-Star Blue Card"
},

[69] = {id=69,
description="Three-Star Green Card"
},

[70] = {id=70,
description="Two-Star Yellow Card"
},

[71] = {id=71,
description="Insufficient retreats for today"
},

[72] = {id=72,
description="Retreat successful, you have successfully retreated in %d rounds"
},

[73] = {id=73,
description="It is not time for free recruitment, recruiting will cost you %d gold"
},

[74] = {id=74,
description="Energy level:"
},

[75] = {id=75,
description="Experience level:"
},

[76] = {id=76,
description="Round %d:"
},

[77] = {id=77,
description="When you are unable to defeat the current monster, you can choose to retreat, and continue with the challenge after you have grown. You can retreat 50 times a day."
},

[78] = {id=78,
description="Skill damage is affected by Chakra. Skill damage is doubled with every 500 Chakra points."
},

[79] = {id=79,
description="Retreat failed"
},

[80] = {id=80,
description="Skill damage increase: %d"
},

[81] = {id=81,
description="(Chakra increase: %d)"
},

[82] = {id=82,
description="Position empty"
},

[83] = {id=83,
description="War has not started (State official can start wars)"
},

[84] = {id=84,
description="War has not started, it will begin at %s%s against %s!"
},

[85] = {id=85,
description="War in progress, join in the fight for the honour of your nation!"
},

[86] = {id=86,
description="Today"
},

[87] = {id=87,
description="Tomorrow"
},

[88] = {id=88,
description="You are already in the position"
},

[89] = {id=89,
description="Your country has already started a war"
},

[90] = {id=90,
description="This country has already started a war. Please choose another country."
},

[91] = {id=91,
description="You are currently not an official, hence you cannot start a war."
},

[92] = {id=92,
description="%s shinobi %s has defeated %s shinobi %s, and won %d times consecutively!"
},

[93] = {id=93,
description="Victory in the war! Your country won the war against %s! (Click the box to claim your reward)"
},

[94] = {id=94,
description="Loser! Your country has lost the war against %s, please fight harder."
},

[95] = {id=95,
description="War in progress: Your country is fighting with %s currently, kill for your country!"
},

[96] = {id=96,
description="You are not in this position, hence you cannot claim this reward."
},

[97] = {id=97,
description="It is not yet time to claim your reward."
},

[98] = {id=98,
description="War has not started."
},

[99] = {id=99,
description="Please choose a country to start a war against."
},

[100] = {id=100,
description="Reward claimed successfully."
},

[101] = {id=101,
description="Land of Wind"
},

[102] = {id=102,
description="Land of Thunder"
},

[103] = {id=103,
description="Land of Water"
},

[104] = {id=104,
description="Land of Fire"
},

[105] = {id=105,
description="Land of Earth"
},

[106] = {id=106,
description="Do you want to spend %d gold to purchase 10 resurrection counts."
},

[107] = {id=107,
description="Do you want to fight to be a defender of the country?"
},

[108] = {id=108,
description="Succeeded."
},

[109] = {id=109,
description="No treasure to turn in."
},

[110] = {id=110,
description="You have reached the maximum number of steals for today."
},

[111] = {id=111,
description="Do you want to spend %d gold to remove CD time?"
},

[112] = {id=112,
description="Please choose the country to steal from."
},

[113] = {id=113,
description="Treasure successfully obtained, turn in to receive %d silver."
},

[114] = {id=114,
description="Lucky! %s has no defenders, 1 national treasure obtained successfully."
},

[115] = {id=115,
description="You are incredibly brave, you have defeated %ss defender %s, and have obtained 1 national treasure successfully."
},

[116] = {id=116,
description="You were defeated by %ss defender %s, and failed to get any national treasure."
},

[117] = {id=117,
description="Plunder failed, please try harder."
},

[118] = {id=118,
description="You have no more challenges today."
},

[119] = {id=119,
description="Reward claimed successfully."
},

[120] = {id=120,
description="Purchase failed."
},

[121] = {id=121,
description="Insufficient %s, do you wish to purchase %s?"
},

[122] = {id=122,
description="Energy"
},

[123] = {id=123,
description="Duel Points"
},

[124] = {id=124,
description="Silver"
},

[125] = {id=125,
description="Account name is too long"
},

[126] = {id=126,
description="You have no more chance to bet."
},

[127] = {id=127,
description="Synthesis started"
},

[128] = {id=128,
description="Card has reached its maximum level, unable to strengthen further."
},

[129] = {id=129,
description="Insufficient silver to strengthen."
},

[130] = {id=130,
description="You dont have cards with 1 star or 2 stars."
},

[131] = {id=131,
description="You cannot choose more than 30 cards to strengthen at one time."
},

[132] = {id=132,
description="Player %s wishes to be your friend."
},

[133] = {id=133,
description="Friend request sent successfully."
},

[134] = {id=134,
description="You are already friends, unable to add again."
},

[135] = {id=135,
description="You are already a defender of the country."
},

[136] = {id=136,
description="Enter the name to search for:"
},

[137] = {id=137,
description="Please choose some cards"
},

[138] = {id=138,
description="Campaign successfully"
},

[139] = {id=139,
description="Spend %d gold to remove cool-down?"
},

[140] = {id=140,
description="Account name can only be letters or numbers"
},

[141] = {id=141,
description="Password can only be letters or numbers"
},

[142] = {id=142,
description="Account name has to be between 6-30 characters"
},

[143] = {id=143,
description="Password has to be between 6-30 characters"
},

[144] = {id=144,
description="Please choose your country"
},

[145] = {id=145,
description="Please choose a teammate"
},

[146] = {id=146,
description="Name cannot consist of special characters"
},

[147] = {id=147,
description="Name has to be within 2 - 6 words"
},

[148] = {id=148,
description="You have passed all difficulty levels of this chapter, please choose another chapter to train"
},

[149] = {id=149,
description="You are not qualified to claim reward."
},

[150] = {id=150,
description="It is not yet time for claiming of rewards."
},

[151] = {id=151,
description="Removed cool-down successfully"
},

[152] = {id=152,
description="Player %s has defeated you in the celestial ladder, your ranking in the celestial ladder has dropped to %d."
},

[153] = {id=153,
description="%ss player %s has come to plunder our national treasure, but was defeated by you!"
},

[154] = {id=154,
description="%ss player %s has come to plunder our national treasure. He defeated you and stole one piece!"
},

[155] = {id=155,
description="Our countrys %s has defeated you, and stole %s position once belonged to you."
},

[156] = {id=156,
description="Our countrys %s came to steal your %s position, but was defeated by you!"
},

[157] = {id=157,
description="Hokage"
},

[158] = {id=158,
description="TsuchiKage"
},

[159] = {id=159,
description="KazeKage"
},

[160] = {id=160,
description="MizuKage"
},

[161] = {id=161,
description="RaiKage"
},

[162] = {id=162,
description="Custodian"
},

[163] = {id=163,
description="Elder"
},

[164] = {id=164,
description="You have fought it, please come again tomorrow."
},

[165] = {id=165,
description="Please defeat the previous ones first."
},

[166] = {id=166,
description="Currently not open"
},

[167] = {id=167,
description="Arena"
},

[168] = {id=168,
description="National treasure"
},

[169] = {id=169,
description="War"
},

[170] = {id=170,
description="Register Account"
},

[171] = {id=171,
description="Please enter a correct email address"
},

[172] = {id=172,
description="Wrong password"
},

[173] = {id=173,
description="Unable to claim arena gift at this moment"
},

[174] = {id=174,
description="It is not yet time for claiming of gift."
},

[175] = {id=175,
description="Player %s sends you a friend request."
},

[176] = {id=176,
description="No war notifications."
},

[177] = {id=177,
description="Insufficient gold."
},

[178] = {id=178,
description="There is no more chance to bet."
},

[179] = {id=179,
description="Friend request sent successfully."
},

[180] = {id=180,
description="For the security of your data, you are unable to buy another monthly card within 30 seconds"
},

[181] = {id=181,
description="Monthly card purchased successfully. Please enter the event again to claim gold"
},

[182] = {id=182,
description="Gold purchased successfully."
},

[183] = {id=183,
description="Growth is to be opened soon"
},

[184] = {id=184,
description="Energy and duel levels are full, you can continue your adventure!"
},

[185] = {id=185,
description="You are not qualified at the moment. Charge any amount to claim."
},

[186] = {id=186,
description="You have obtained 5 Four-star shinobi card fragments"
},

[187] = {id=187,
description="You have obtained 5 Five-star shinobi card fragments"
},

[188] = {id=188,
description="You have already claimed the first charge gift pack"
},

[189] = {id=189,
description="Our countrys player %s has defeated you and stolen your position as Defender of the Country"
},

[190] = {id=190,
description="%d chances daily, get up to ×%d silver, and minimum ×%d"
},

[191] = {id=191,
description="Try your luck friend! Free %d tries daily."
},

[192] = {id=192,
description="You still have %d free tries, win a minimum of %d silver."
},

[193] = {id=193,
description="Insufficient shakes left, please come again tomorrow!"
},

[194] = {id=194,
description="You have used up your free shakes, continue to shake the tree for %d gold"
},

[195] = {id=195,
description="Chapter 1"
},

[196] = {id=196,
description="Chapter 2"
},

[197] = {id=197,
description="Chapter 3"
},

[198] = {id=198,
description="Chapter 4"
},

[199] = {id=199,
description="Chapter 5"
},

[200] = {id=200,
description="Chapter 6"
},

[201] = {id=201,
description="Chapter 7"
},

[202] = {id=202,
description="Chapter 8"
},

[203] = {id=203,
description="Chapter 9"
},

[204] = {id=204,
description="Chapter 10"
},

[205] = {id=205,
description="Chapter 11"
},

[206] = {id=206,
description="Chapter 12"
},

[207] = {id=207,
description="Chapter 13"
},

[208] = {id=208,
description="Chapter 14"
},

[209] = {id=209,
description="Chapter 15"
},

[210] = {id=210,
description="Chapter 16"
},

[211] = {id=211,
description="Chapter 17"
},

[212] = {id=212,
description="Chapter 18"
},

[213] = {id=213,
description="Congratulations on passing the training %s-%s"
},

[214] = {id=214,
description="Difficulty level 2"
},

[215] = {id=215,
description="Difficulty Level 3"
},

[216] = {id=216,
description="Difficulty Level 4"
},

[217] = {id=217,
description="Difficulty Level 5"
},

[218] = {id=218,
description="Difficulty Level 6"
},

[219] = {id=219,
description="Difficulty Level 7"
},

[220] = {id=220,
description="Difficulty Level 8"
},

[221] = {id=221,
description="Difficulty level  9"
},

[222] = {id=222,
description="Difficulty Level 10"
},

[223] = {id=223,
description="Difficulty Level 11"
},

[224] = {id=224,
description="Difficulty Level 12"
},

[225] = {id=225,
description="Difficulty Level 13"
},

[226] = {id=226,
description="Difficulty Level 14"
},

[227] = {id=227,
description="Difficulty Level 15"
},

[228] = {id=228,
description="(%s%s unlocked!)"
},

[229] = {id=229,
description="(%s all difficulties completed!)"
},

[230] = {id=230,
description="Please choose the card you wish to grow."
},

[231] = {id=231,
description="You have reached the highest growth level."
},

[232] = {id=232,
description="You have reached automatic growth level."
},

[233] = {id=233,
description="Insufficient Sage Stones."
},

[234] = {id=234,
description="Please deactivate automative growth first"
},

[235] = {id=235,
description="Gold"
},

[256] = {id=256,
description="Silver"
},

[257] = {id=257,
description="Minimum attack increased"
},

[258] = {id=258,
description="Maximum attack increased"
},

[259] = {id=259,
description="Minimum defense increased"
},

[260] = {id=260,
description="Maximum defense increased"
},

[261] = {id=261,
description="Minimum Chakra increased"
},

[262] = {id=262,
description="Maximum Chakra increased"
},

[263] = {id=263,
description="Possibility of maximum defense"
},

[264] = {id=264,
description="Possibility of maximum attack"
},

[265] = {id=265,
description="%d days %d hours %d minutes %d seconds"
},

[266] = {id=266,
description="Please add QQ group: 19148072"
},

[267] = {id=267,
description="Are you sure to spend %d gold for the draw?"
},

[268] = {id=268,
description="Wheel"
},

[269] = {id=269,
description="Please enter invitation code:"
},

[270] = {id=270,
description="Please enter account name"
},

[271] = {id=271,
description="Materials"
},

[272] = {id=272,
description="Unlock at Lv.%d"
},

[273] = {id=273,
description="Please choose the cards you wish to reincarnate"
},

[274] = {id=274,
description="You have reached the highest level of reincarnation"
},

[275] = {id=275,
description="Cards require the highest level for reincarnation."
},

[276] = {id=276,
description="Insufficient Reincarnation pills"
},

[277] = {id=277,
description="Insufficient materials"
},

[278] = {id=278,
description="No Lv.50 cards."
},

[279] = {id=279,
description="%d days before"
},

[280] = {id=280,
description="%d hours before"
},

[281] = {id=281,
description="%d minutes before"
},

[282] = {id=282,
description="No attack video available currently"
},

[283] = {id=283,
description="You have no more resurrection counts, automatic war will stop."
},

[284] = {id=284,
description="Are you sure to spend %d gold for autmoatic war? (Automatic war will stop after exiting the game, it will start when you re-enter the game.)"
},

[285] = {id=285,
description="Gained %d silver"
},

[286] = {id=286,
description="Gained %d gold"
},

[287] = {id=287,
description="Come again tomorrow, and gain 280 gold for a login reward."
},

[288] = {id=288,
description="This level requires level 10, work harder!"
},

[289] = {id=289,
description="Please choose a card"
},

[290] = {id=290,
description="Insufficient potential potion"
},

[291] = {id=291,
description="Card has no more usable potential value"
},

[292] = {id=292,
description="You have used up the number of tries for today, are you sure to spend %d gold to continue?"
},

[293] = {id=293,
description="Please complete the prior chapters first!"
},

[294] = {id=294,
description="You need gold:"
},

[295] = {id=295,
description="You need silver:"
},

[296] = {id=296,
description="You have: %d"
},

[297] = {id=297,
description="You have insufficient recruitment orders"
},

[298] = {id=298,
description="Use up recruitment orders x %d"
},

[299] = {id=299,
description="Ninja Soul"
},

[300] = {id=300,
description="Shinobi attack increase: %.2f%%"
},

[301] = {id=301,
description="Shinobi defense increase: %.2f%%"
},

[302] = {id=302,
description="Shinobi Chakra increase: %.2f%%"
},

[303] = {id=303,
description="Ninjitsu activation rate increase: %.2f%%"
},

[304] = {id=304,
description="You can skip the battleafter the first charge or after level 30"
},

[305] = {id=305,
description="Fragments"
},

[306] = {id=306,
description="You can only reincarnate after highest level is reached"
},

[307] = {id=307,
description="Are you sure to spend %d gold to synthesise immediately?"
},

[308] = {id=308,
description="Please obtain seal first."
},

[309] = {id=309,
description="Seal fragments not enough."
},

[310] = {id=310,
description="Every five consecutive growths will use up %d gold. (Automatic growth will deduct gold in the same way)"
},

[311] = {id=311,
description="Gold"
},

[312] = {id=312,
description="You dont have this material card currently: %s"
},

[313] = {id=313,
description="You dont have this material card currently: First Reincarnation %s"
},

[314] = {id=314,
description="You dont have this material card currently: Second Reincarnation %s"
},

[315] = {id=315,
description="Only VIP3 or above players can by growth fund"
},

[316] = {id=316,
description="Used successfully"
},

[317] = {id=317,
description="Open at Lv.%d"
},

[318] = {id=318,
description="Successfully activated"
},

[319] = {id=319,
description="Failed to activate"
},

[10018] = {id=10018,
description="Youve registered too frequently. Try again later!"
},

[400001] = {id=400001,
description="Failed to gain the data of Eight Gates Released Formation"
},

[400002] = {id=400002,
description="Failed to set the data of Eight Gates Released Formation"
},

[400003] = {id=400003,
description="Failed to gain the setting of Eight Gates Released Formation"
},

[400004] = {id=400004,
description="Insufficient gold"
},

[400005] = {id=400005,
description="Insufficient Silver"
},

[400006] = {id=400006,
description="Insufficient souls. Go training!"
},

[400007] = {id=400007,
description="Already the highest multiples"
},

[500001] = {id=500001,
description="Not reached the relative level"
},

[410001] = {id=410001,
description="You havent spent enough Gold"
},

[410002] = {id=410002,
description="Youve already claimed this reward today"
},

[420000] = {id=420000,
description="No reward to claim"
},

[420001] = {id=420001,
description="Not in event time"
},

[420002] = {id=420002,
description="You can only claim todays reward"
},

[430000] = {id=430000,
description="Not in event time"
},

[430001] = {id=430001,
description="You cant recharge such low amount"
},

[430002] = {id=430002,
description="No reward to claim"
},

[440000] = {id=440000,
description="invalid gift id"
},

[440001] = {id=440001,
description="Packs reached the maximum number of purchases"
},

[440002] = {id=440002,
description="need nore gold"
},

[440003] = {id=440003,
description="Activity does not start"
},

[630001] = {id=630001,
description="Already sign"
},

[630002] = {id=630002,
description="can not sign today"
},

[610003] = {id=610003,
description="need three or more stars card"
},

[610004] = {id=610004,
description="Points inadequate"
},
[610005] = {id=610005,
description="invalid box id"
},
[610006] = {id=610006,
description="All levels have been completed"
},
[610007] = {id=610007,
description="Challenge times has been exhausted"
},
[610008] = {id=610008,
description="Please set the lineup"
},
[610009] = {id=610009,
description="Already receive awards"
},
[610010] = {id=610010,
description="The hero has fallen"
},
[610011] = {id=610011,
description="this level is not completed"
},
[610012] = {id=610012,
description="this level has been completed"
},

}
