import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

import Account "Account";
import { accountsEqual; accountsHash; accountBelongsToPrincipal } "Account";
// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
import Principal "mo:base/Principal";

actor class MotoCoin() {
	public type Account = Account.Account;
	let ledger = TrieMap.TrieMap<Account, Nat>(accountsEqual, accountsHash);

	// Returns the name of the token
	public query func name() : async Text {
		return "MotoCoin";
	};

	// Returns the symbol of the token
	public query func symbol() : async Text {
		return "MOC";
	};

	// Returns the the total number of tokens on all accounts
	public func totalSupply() : async Nat {
		var sum = 0;
		for (bal in ledger.vals()) {
			sum += bal;
		};
		sum;
	};

	// Returns the default transfer fee
	public query func balanceOf(account : Account) : async (Nat) {
		let _balance = ledger.get(account);
		switch (_balance) {
			case (null) {
				return 0;
			};
			case (?_balance) {
				return (_balance);
			};
		};
	};

	// Transfer tokens to another account
	public shared ({ caller }) func transfer(
		from : Account,
		to : Account,
		amount : Nat
	) : async Result.Result<(), Text> {
		Debug.print(Principal.toText(caller));

		if (accountsEqual(from, to)) {
			#err("from and to should not be equal");
		} else if (accountBelongsToPrincipal(from, caller)) {
			let balFrom = await balanceOf(from);
			let balTo = await balanceOf(to);
			if (balFrom < amount) {
				#err("not enough balance to transfer");
			} else {
				let old1 = ledger.replace(from, balFrom -amount);
				let old2 = ledger.replace(to, balFrom +amount);
				#ok();
			};
		} else {
			#err("principal is not belongs to account");
		};
	};

	// Airdrop 1000 MotoCoin to any student that is part of the Bootcamp.
	public func airdrop() : async Result.Result<(), Text> {
		let bootcampLocalActor = actor ("rww3b-zqaaa-aaaam-abioa-cai") : actor {
			getAllStudentsPrincipal : shared () -> async [Principal];
		};
		let students = await bootcampLocalActor.getAllStudentsPrincipal();

		for (student in students.vals()) {
			let studentAcc : Account = {
				owner = student;
				subaccount = null;
			};
			let oldBalance = await balanceOf(studentAcc);
			let _ = ledger.replace(studentAcc, oldBalance + 100);
		};
		#ok();
	};
};
