
/datum/money_account
	var/owner_name = ""
	var/creation_time = 0
	var/account_number = ""
	var/remote_access_pin = 0
	var/money = 0
	var/list/transaction_log = list() //TODO: database this? not if every remote terminal access is a transaction though...
	var/security_level = 0	//0 - auto-identify from worn ID, require only account number
							//1 - require manual login / account number and pin
							//2 - require card and manual login

// needs to be called before the world reboots or dies, or progress will be lost
/proc/handle_money_persistence()
	var/list/area/escape_locations = list(/area/shuttle/escape/centcom, /area/shuttle/escape_pod1/centcom, /area/shuttle/escape_pod2/centcom, /area/shuttle/escape_pod3/centcom, /area/shuttle/escape_pod5/centcom)
	// TODO: more complex survival logic involving intact structures that arent a station
	for(var/mob/M in player_list)
		if(M.client && M.mind && M.mind.initial_account)
			var/escaped = 0
			var/alive   = 0
			if(M.stat != DEAD)
				alive   = 1
			if(M.loc && M.loc.loc && M.loc.loc.type in escape_locations)
				escaped = 1

			if (escaped || alive)
				var/value = 0
				for (var/obj/item/weapon/spacecash/c in M.search_contents_for(/obj/item/weapon/spacecash))
					world << "found '[c]' on [M] worth [c.worth] credits"
					value += c.worth
				M.mind.initial_account.deposit(value)
				world << "[value] added to [M]'s bank account"

/datum/money_account/proc/deposit(amount=0)
	if(dbcon.IsConnected())
		var/DBQuery/query = dbcon.NewQuery("UPDATE `tgstation`.`ntcred_accounts` SET `balance`=`balance`+[amount] where `account_number`=[account_number]")
		if (!query.Execute())
			world << query.ErrorMsg() //TODO: proper error message instead of piping to world
	money += amount

/datum/money_account/proc/withdraw(amount=0)
	if(dbcon.IsConnected())
		var/DBQuery/query = dbcon.NewQuery("UPDATE `tgstation`.`ntcred_accounts` SET `balance`=`balance`-[amount] where `account_number`=[account_number]")
		if (!query.Execute())
			world << query.ErrorMsg() //TODO: proper error message instead of piping to world
	money -= amount

/datum/transaction
	var/target_name = ""
	var/purpose = ""
	var/amount = 0
	var/time = 0
	var/source_terminal = ""

//TODO: use proper error reporting functions
/proc/get_account(var/mob/living/M, var/starting_funds = 0)
	// check the database for an existing account
	var/canonical_key = ckey(M.key)

	//create an entry in the account transaction log for when it was created
	//TODO: store transaction history in database? probably not
	var/datum/transaction/T = new()
	T.source_terminal = "NTCREDIT BACKBONE #[rand(111,1111)]"
	T.purpose = "Update local NTCREDIT terminal network with account information."
	T.time = world.realtime
	//create an entry in the account transaction log for when it was created
	T.target_name = M.real_name

	//create a new account
	var/datum/money_account/A = new()
	A.owner_name = M.real_name

	//initial fallback values (to be overridden if database entry is found with different numbers)
	A.money  = starting_funds
	T.amount = starting_funds
	A.creation_time = world.realtime
	A.account_number = num2text(rand(111111, 999999))
	A.remote_access_pin = rand(1111, 111111)

	establish_db_connection()
	if(dbcon.IsConnected())
		var/DBQuery/check_query = dbcon.NewQuery("SELECT * from ntcred_accounts WHERE ckey='[canonical_key]'")
		if (!check_query.NextRow())
			//create new entry if one doesn't exist
			var/DBQuery/insert_query = dbcon.NewQuery("INSERT INTO `tgstation`.`ntcred_accounts` (`account_number`, `ckey`, `creation_time`, `balance`, `pin`) VALUES (UUID_SHORT(), '[sql_sanitize_text(canonical_key)]', [A.creation_time], [starting_funds], [A.remote_access_pin])")
			insert_query.Execute()
			check_query.Execute()

		if (check_query.NextRow()) //only grab first row (in theory DB will assure there will only be one)
			A.account_number    = check_query.item[1]
			A.creation_time     = text2num(check_query.item[3])
			A.money             = text2num(check_query.item[4])
			T.amount            = text2num(check_query.item[4])
			A.remote_access_pin = text2num(check_query.item[5])
		else
			world << "Financial DB entry not found." //TODO: proper error message instead of pipe to world
	else
		//fallback mode
		world << "Bank account for [M.key] created in fallback mode." //TODO: proper error message instead of piping to world

	//add the account
	A.transaction_log.Add(T)
	all_money_accounts[A.account_number] = A

	return A

/proc/charge_to_account(var/attempt_account_number, var/source_name, var/purpose, var/terminal_id, var/amount)
	if (attempt_account_number in all_money_accounts)
		var/datum/money_account/D = all_money_accounts[attempt_account_number]

		D.deposit(amount)

		//create a transaction log entry
		var/datum/transaction/T = new()
		T.target_name = source_name
		T.purpose = purpose
		if(amount < 0)
			T.amount = "([amount])"
		else
			T.amount = "[amount]"
		// gameyear is current year + 544 years, so add that much to byondtime (byond time is in .1 seconds)
		T.time = world.realtime
		T.source_terminal = terminal_id
		D.transaction_log.Add(T)

		return 1

	return 0

//this returns the first account datum that matches the supplied accnum/pin combination, it returns null if the combination did not match any account
/proc/attempt_account_access(var/attempt_account_number, var/attempt_pin_number)
	if (attempt_account_number in all_money_accounts)
		var/datum/money_account/D = all_money_accounts[attempt_account_number]
		if ((D.security_level > 0 && D.remote_access_pin == text2num(attempt_pin_number)) || (D.security_level == 0))
			return D

/proc/find_account(var/account_number)
	if (account_number in all_money_accounts)
		return all_money_accounts[account_number]
	return 0
