import Types "./Types";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import IC "./ic";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Canister "mo:matchers/Canister";
import Array "mo:base/Array";

actor class Verifier() {
	type StudentProfile = Types.StudentProfile;

	stable var stores : [(Principal, StudentProfile)] = [];
	let studentProfileStore = HashMap.fromIter<Principal, StudentProfile>(stores.vals(), stores.size(), Principal.equal, Principal.hash);

	system func preupgrade() {
		stores := Iter.toArray(studentProfileStore.entries());
	};

	system func postupgrade() {
		stores := [];
	};

	// STEP 1 - BEGIN
	public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
		let currentProfile = studentProfileStore.get(caller);

		Debug.print(Principal.toText(caller));

		switch (currentProfile) {
			case (null) {
				studentProfileStore.put(caller, profile);
				#ok();
			};
			case (?currentProfile) {
				#err("profile is existed");
			};
		};
	};

	public shared ({ caller }) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
		let currentProfile = studentProfileStore.get(p);

		switch (currentProfile) {
			case (null) {
				#err("profile is not existed");
			};
			case (?currentProfile) {
				#ok(currentProfile);
			};
		};
	};

	public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
		let currentProfile = studentProfileStore.get(caller);

		switch (currentProfile) {
			case (null) {
				#err("profile is not existed");
			};
			case (?currentProfile) {
				let _ = studentProfileStore.replace(caller, profile);
				#ok();
			};
		};
	};

	public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
		let currentProfile = studentProfileStore.get(caller);

		switch (currentProfile) {
			case (null) {
				#err("profile is not existed");
			};
			case (?currentProfile) {
				let _ = studentProfileStore.remove(caller);
				#ok();
			};
		};
	};

	// step 2
	type calculatorInterface = Types.CalculatorInterface;
	public type TestResult = Types.TestResult;
	public type TestError = Types.TestError;
	public type ManagementCanisterInterface = IC.ManagementCanisterInterface;
	public type CanisterId = IC.CanisterId;

	public func test(canisterId : Principal) : async TestResult {
		try {
			let testCanister = actor (Principal.toText(canisterId)) : calculatorInterface;
			let _reset = await testCanister.reset();
			let addResult = await testCanister.add(5);
			if (addResult != 5) {
				return #err(#UnexpectedValue("wrong value"));
			};
			let _rest2 = await testCanister.reset();
			let subResult = await testCanister.sub(2);
			if (subResult != -2) {
				return #err(#UnexpectedValue("wrong value"));
			};
			let resetResult = await testCanister.reset();
			if (resetResult != 0) {
				return #err(#UnexpectedValue("wrong value"));
			};

			return #ok();
		} catch (err) {
			Debug.print("error " # Error.message(err));
			#err(#UnexpectedError(Error.message(err)));
		};
	};

	// step 3
	func parseControllersFromCanisterStatusErrorIfCallerNotController(errorMessage : Text) : [Principal] {
		let lines = Iter.toArray(Text.split(errorMessage, #text("\n")));
		let words = Iter.toArray(Text.split(lines[1], #text(" ")));
		var i = 2;
		let controllers = Buffer.Buffer<Principal>(0);
		while (i < words.size()) {
			controllers.add(Principal.fromText(words[i]));
			i += 1;
		};
		Buffer.toArray<Principal>(controllers);
	};

	public func testTrapped(canisterId : Principal, p : Principal) : async Text {
		try {
			let checkCanister = actor ("aaaaa-aa") : ManagementCanisterInterface;
			let _ = await checkCanister.canister_status({ canister_id = canisterId });
			return "";
		} catch (err) {
			Debug.print("error " # Error.message(err));
			Error.message(err);
		};
	};

	public func verifyOwnership(canisterId : Principal, p : Principal) : async Bool {
		try {
			let checkCanister = actor ("aaaaa-aa") : ManagementCanisterInterface;
			let result = await checkCanister.canister_status({
				canister_id = canisterId;
			});
			let controllers = result.settings.controllers;
			let isContain = Array.find<Principal>(
				controllers,
				func(controller : Principal) : Bool {
					Principal.equal(controller, p);
				}
			);
			switch (isContain) {
				case (null) false;
				case (?isContain) true;
			};

		} catch (err) {
			Debug.print("error " # Error.message(err));
			let controllers = parseControllersFromCanisterStatusErrorIfCallerNotController(Error.message(err));
			let isContain = Array.find<Principal>(
				controllers,
				func(controller : Principal) : Bool {
					Principal.equal(controller, p);
				}
			);
			switch (isContain) {
				case (null) false;
				case (?isContain) true;
			};
		};
	};

	// step 5

	public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<(), Text> {
		try {
			let studentProfile = studentProfileStore.get(p);
			switch (studentProfile) {
				case (null) {
					#err("profile is not found");
				};
				case (?studentProfile) {
					let isOwner = await verifyOwnership(canisterId, p);
					switch (isOwner) {
						case (false) #err("principal is not the owner of canister");
						case (true) {
							let testResult = await test(canisterId);
							switch (testResult) {
								case (#err(failed)) {
									switch (failed) {
										case (#UnexpectedValue(msg)) {
											#err("unexpected value " # msg);
										};
										case (#UnexpectedError(msg)) {
											#err("unexpected error " # msg);
										};
									};
								};
								case (#ok) {
									let graduatedProfile : StudentProfile = {
										name = studentProfile.name;
										team = studentProfile.team;
										graduate = true;
									};
									let _ = studentProfileStore.replace(p, graduatedProfile);
									#ok();
								};
							};
						};
					};
				};
			};
		} catch (err) {
			Debug.print("error " # Error.message(err));
			#err(Error.message(err));
		};
	};
};
