import Type "Types";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Order "mo:base/Order";
import Int "mo:base/Int";

actor class StudentWall() {
	type Message = Type.Message;
	type Content = Type.Content;

	private func keyHash(num : Nat) : Hash.Hash {
		return Text.hash(Nat.toText(num));
	};

	let wall = HashMap.HashMap<Nat, Message>(0, Nat.equal, keyHash);

	// Add a new message to the wall
	public shared ({ caller }) func writeMessage(c : Content) : async Nat {
		let newMessage : Message = {
			vote = 0;
			content = c;
			creator = caller;
		};
		let index = wall.size();
		wall.put(index, newMessage);
		return index;
	};

	// Get a specific message by ID
	public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
		if (messageId > wall.size()) {
			#err("Message ID is not existing");
		} else {
			let message = wall.get(messageId);
			switch (message) {
				case (null) {
					#err("Message is null");
				};
				case (?message) {
					let res = wall.get(messageId);
					#ok(message);
				};
			};
		};
	};

	// Update the content for a specific message by ID
	public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {
		if (messageId > wall.size()) {
			#err("Message ID is not existing");
		} else {
			let message = wall.get(messageId);
			switch (message) {
				case (null) {
					#err("Message is null");
				};
				case (?message) {
					if (Principal.equal(message.creator, caller)) {
						let updatedMessage : Message = {
							vote = message.vote;
							content = c;
							creator = caller;
						};
						let res = wall.replace(messageId, updatedMessage);
						#ok();
					} else {
						#err("Not the owner of the message");
					};

				};
			};
		};
	};

	// Delete a specific message by ID
	public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
		if (messageId > wall.size()) {
			#err("Message ID is not existing");
		} else {
			let message = wall.get(messageId);
			switch (message) {
				case (null) {
					#err("Message is null");
				};
				case (?message) {
					if (Principal.equal(message.creator, caller)) {
						let res = wall.delete(messageId);
						#ok();
					} else {
						#err("Not the owner of the message");
					};

				};
			};
		};
	};

	// Voting
	public func upVote(messageId : Nat) : async Result.Result<(), Text> {
		if (messageId > wall.size()) {
			#err("Message ID is not existing");
		} else {
			let message = wall.get(messageId);
			switch (message) {
				case (null) {
					#err("Message is null");
				};
				case (?message) {
					let updatedMessage : Message = {
						vote = message.vote + 1;
						content = message.content;
						creator = message.creator;
					};
					let res = wall.replace(messageId, updatedMessage);
					#ok();
				};
			};
		};
	};

	public func downVote(messageId : Nat) : async Result.Result<(), Text> {
		if (messageId > wall.size()) {
			#err("Message ID is not existing");
		} else {
			let message = wall.get(messageId);
			switch (message) {
				case (null) {
					#err("Message is null");
				};
				case (?message) {
					let updatedMessage : Message = {
						vote = message.vote - 1;
						content = message.content;
						creator = message.creator;
					};
					let res = wall.replace(messageId, updatedMessage);
					#ok();
				};
			};
		};
	};

	// Get all messages
	public func getAllMessages() : async [Message] {
		let res = Buffer.Buffer<Message>(0);
		for (message in wall.vals()) {
			res.add(message);
		};
		return Buffer.toArray(res);
	};

	// Get all messages ordered by votes

	private func sortByVote(message1 : Message, message2 : Message) : Order.Order {
		switch (Int.compare(message1.vote, message2.vote)) {
			case (#greater) return #less;
			case (#less) return #greater;
			case (_) return #equal;
		};
	};

	public func getAllMessagesRanked() : async [Message] {
		let res = Buffer.Buffer<Message>(0);
		for (message in wall.vals()) {
			res.add(message);
		};
		var unsortArray = Buffer.toArray(res);
		var sortedArray = Array.sort(unsortArray, sortByVote);
		Array.reverse(sortedArray);
	};
};
