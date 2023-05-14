import Result "mo:base/Result";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Type "./types";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Text "mo:base/Text";

actor HomeworkDiary {
	type Homework = Type.Homework;

	var homeworkDiary = Buffer.Buffer<Homework>(0);

	// Add a new homework task
	public shared func addHomework(homework : Homework) : async Nat {
		homeworkDiary.add(homework);
		homeworkDiary.size() -1;
	};

	// Get a specific homework task by id
	public shared query func getHomework(id : Nat) : async Result.Result<Homework, Text> {
		let size = homeworkDiary.size();

		if (id >= size) {
			#err("homework is not exist");
		} else {
			let homework = homeworkDiary.get(id);
			#ok(homework);
		};

	};

	// Update a homework task's title, description, and/or due date
	public shared func updateHomework(id : Nat, homework : Homework) : async Result.Result<(), Text> {

		let size = homeworkDiary.size();

		if (id >= size) {
			#err("homework is not exist");
		} else {
			let oldhomework = homeworkDiary.get(id);
			try {
				homeworkDiary.put(id, homework);
				#ok();
			} catch (err : Error) {
				#err(Error.message(err));
			};
		};
	};

	// Mark a homework task as completed
	public shared func markAsCompleted(id : Nat) : async Result.Result<(), Text> {
		let size = homeworkDiary.size();
		if (id >= size) {
			#err("homework is not exist");
		} else {
			let homework = homeworkDiary.get(id);
			try {
				let newHomework : Type.Homework = {
					title = homework.title;
					description = homework.description;
					dueDate = homework.dueDate;
					completed = true;
				};
				homeworkDiary.put(id, newHomework);
				#ok();
			} catch (err : Error) {
				#err(Error.message(err));
			};
		};
	};

	// Delete a homework task by id
	public shared func deleteHomework(id : Nat) : async Result.Result<(), Text> {
		let size = homeworkDiary.size();
		if (id >= size) {
			#err("homework is not exist");
		} else {
			try {
				let deletedHomework = homeworkDiary.remove(id);
				#ok();
			} catch (err : Error) {
				#err(Error.message(err));
			};
		};
	};

	// Get the list of all homework tasks
	public shared query func getAllHomework() : async [Homework] {
		return Buffer.toArray(homeworkDiary);
	};

	private func isPendingHomework(homework : Homework) : Bool {
		return homework.completed == false;
	};

	// Get the list of pending (not completed) homework tasks
	public shared query func getPendingHomework() : async [Homework] {
		var array = Buffer.toArray(homeworkDiary);
		return Array.filter(array, isPendingHomework);
	};

	private func isContain(homework : Homework, searchTerm : Text) : Bool {
		let isInTitle = Text.contains(homework.title, #text searchTerm);
		let isInDesc = Text.contains(homework.description, #text searchTerm);

		return isInTitle or isInDesc;
	};

	// Search for homework tasks based on a search terms
	public shared query func searchHomework(searchTerm : Text) : async [Homework] {
		var array = Buffer.toArray(homeworkDiary);
		let filtered = Array.filter<Homework>(
			array,
			func(homework : Homework) { isContain(homework, searchTerm) }
		);
	};
};
