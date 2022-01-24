/**
* Name: A3Task1
* Author: Sara Moazez Gharebagh and Sebastian Lihammer
*/

model A3Task1

global{
	int number_of_queens <- 12;
	
	init{
		create Queen number: number_of_queens{
		}
	}
	
	list<Queen> list_of_queens; //Keep a list of queens to find predecessors and successors
	
	// matrix that keeps track of occupied cells/positions
	matrix<bool> cell_occupied <- matrix_with ({number_of_queens, number_of_queens}, false);
	
	// finished_queens[1] = true means queen 1 is on the chessboard
	// when the entire list is true all queens are on the chessboard
	list<bool> finished_queens <- list_with(number_of_queens, false); 
}

grid chessboard skills: [fipa] width: number_of_queens height: number_of_queens{
	rgb color <- bool(((grid_x+grid_y) mod 2)) ? #black : #white;
}

species Queen skills: [moving, fipa]{
	//Ints
	int index_col <- -1; //Our position (column)
	int index_row <- -1; //Our position (row)
	int index_of_queen; //Our index in list_of_queens
	
	//Booleans
	bool added_to_list <- false; //Have we been added to list_of_queens?
	bool tell_succ <- false; //Should we tell our successor to move?
	bool tell_pred <- false; //Should we tell our predecessor to move?
	bool search_for_position <- false; //Should we search for a position?
	
	//Other
	point targetPoint <- nil; //Target locations when we are going to move
	list tried_indexes <- []; //For use when trying positions after successor tells us to move
	
	//Initialize the Queens
	init{
		if(self.added_to_list = false){
			add self to: list_of_queens;
			self.added_to_list <- true;
			index_of_queen <- int(list_of_queens[length(list_of_queens) - 1]); //get our index
			location <- (chessboard[index_of_queen, number_of_queens-1].location + {0,20}); //Place us at the bottom of the map
		}
		//If we are the last queen, we kickstart the position-finding process
		if(length(list_of_queens) = number_of_queens ){
            do start_conversation with:(to: list(list_of_queens[0]), protocol: 'fipa-request', performative: 'inform', contents: ["StartFindingPositionProcess"]);        
            write "Begin the position-finding process!";
        }
	}
	
	//Appearance of the Queens
	aspect base{
		draw cone3D(3,6) at: location color: #gold;
		draw sphere(1.3) at: location + {0,0,5} color: #gold;
	}
	
	//For moving to a location
	reflex moveToTarget when: self.targetPoint != nil
	{
		do goto target: self.targetPoint;
	}
	
	//Tell our successor to move
	reflex inform_successor when: self.tell_succ = true{
		write("" + self + " is telling her successor to move");
		if(self = list_of_queens[number_of_queens - 1]){
			do start_conversation with: (to :: list(list_of_queens[0]), protocol :: 'fipa-request', performative :: 'inform', contents :: ["PredecessorSaysMove"]);
		}
		else{
			do start_conversation with: (to :: list(list_of_queens[index_of_queen +1]), protocol :: 'fipa-request', performative :: 'inform', contents :: ["PredecessorSaysMove"]);
		}
		self.tell_succ <- false;	
	}
	
	//Tell our predecessor to move
	reflex inform_predecessor when: self.tell_pred = true{
		write("" + self + " is telling her predecessor to move");
		if(self = list_of_queens[0]){
			do start_conversation with: (to :: list(list_of_queens[number_of_queens -1]), protocol :: 'fipa-request', performative :: 'inform', contents :: ["SuccessorSaysMove"]);
		}
		else{
			do start_conversation with: (to :: list(list_of_queens[index_of_queen -1]), protocol :: 'fipa-request', performative :: 'inform', contents :: ["SuccessorSaysMove"]);
		}
		self.tell_pred <- false;
	}
	
	//Receiving and reading messages
	reflex read_message when: !(empty(informs)){
		write("" + self + " has received a message");
		message msg <- (informs at 0);
		list<unknown> message_list <- msg.contents;
		string content <- string(message_list[0]);
		
		if content = "StartFindingPositionProcess" {
			write("" + self + " is beginning the position-finding process");
			//The first queen will select a random cell to go to
			self.index_col <- rnd(0,number_of_queens-1);
			self.index_row <- rnd(0,number_of_queens-1);
			write("" + self + " moving to position [" + index_col + "," + index_row + "]");
			self.targetPoint <- chessboard[self.index_col, self.index_row].location;
		}
		
		if content = "PredecessorSaysMove"{
			write("" + self +  " has been told to move by her predecessor");
			self.tried_indexes <- []; //empty the list of tried indexes for when our successor tells us to move
			self.search_for_position <- true;
		}
		
		if content = "SuccessorSaysMove"{
			write("" + self +  " has been told to move by her successor");
			//self.search_for_position <- true;
			//finished_queens[index_of_queen] <- false;
			
			//Go to a random unoccupied position, regardless of if it's safe
			cell_occupied[self.index_col, self.index_row] <- false;
			
			int temp_col <- self.index_col;
			int temp_row <- self.index_row;
			
			if (!(length(tried_indexes) = (number_of_queens * number_of_queens) - number_of_queens)){
				self.index_col <- rnd(0,number_of_queens-1);
				self.index_row <- rnd(0,number_of_queens-1);
				loop while: (cell_occupied[self.index_col, self.index_row] = true or tried_indexes contains [self.index_col, self.index_row]){
					self.index_col <- rnd(0,number_of_queens-1);
					self.index_row <- rnd(0,number_of_queens-1);
				}
				add [self.index_col, self.index_row] to: self.tried_indexes;
			}
			if(self.index_col = temp_col and self.index_row = temp_row){
				write("" + self + " is unable to find an untested spot to move to for her successor");
				write("" + self + " has to tell her predecessor to move");
				self.tell_pred <- true;
			}
			else{
				finished_queens[index_of_queen] <- true;
				self.targetPoint <- chessboard[self.index_col, self.index_row].location;
			}
		}
	}
	
	//Things to do once we've walked to our position
	reflex reached_position when: self.location = self.targetPoint{
		cell_occupied[self.index_col, self.index_row] <- true; //mark the cell we are standing on as occupied
		self.targetPoint <- nil; //reset targetPoint
		
		if(finished_queens contains false){
			self.tell_succ <- true; //it is time to tell our successor to move
		} 
		else{
			bool is_finished <- true;
			loop q over: list_of_queens{
				int row <- q.index_row;
				int col <- q.index_col;
				cell_occupied[col, row] <- false;
				if(!(validate_row(row) = true and validate_col(col) = true and validate_diag(col, row) = true)){
					write("" + q + " is on an unsafe position");
					is_finished <- false;
					cell_occupied[col, row] <- true;
					break;
				}
				cell_occupied[col, row] <- true;
			}
			if(is_finished = true){
				write("Positioning complete :)");
			}
			else{
				self.tell_succ <- true; //it is time to tell our successor to move
			}
		}
	}
	
	reflex find_safe_position when: self.search_for_position = true{
		write("" + self + " is searching for a safe position");
		
		if(self.index_col != -1 and self.index_row != -1){
			 cell_occupied[self.index_col, self.index_row] <- false;
		}
		
		//Loop through every position in the entire chessboard
		loop col from: 0 to: number_of_queens-1{
			loop row from: 0 to: number_of_queens-1{
				write("" + self + "is checking position [" + col +  "," + row + "]");
				//If the cell is not occupied and the row, column or diagonal is valid, it is a safe position
				write(cell_occupied);
				write("cell occupied: " + cell_occupied[col, row] + ", row okay: " + validate_row(row) + ", col okay: " + validate_col(col) + ", diag okay: " + validate_diag(col, row));
				if(cell_occupied[col, row] = false and validate_row(row) = true and validate_col(col) = true and validate_diag(col, row) = true){
					//If we are not already standing here
					if(!(col = self.index_col) and !(row = self.index_row)){
						self.search_for_position <- false;
						self.index_col <- col;
						self.index_row <- row;
						self.targetPoint <- chessboard[self.index_col, self.index_row].location;
						finished_queens[index_of_queen] <- true;
						write("" + self + " moving towards found safe position [" + col +  "," + row + "]");
						break;
					}
				}
			}
			if(self.search_for_position = false){
				break; //If we've broken out of the first loop we need to break out of the second one as well
			}
		}
		//If search_for_position is still true after leaving the loop, we have failed to find a safe position
		if(search_for_position = true){
			self.tell_pred <- true;
			if(self.index_col != -1 and self.index_row != -1){
				cell_occupied[self.index_col, self.index_row] <- true;
			}
			self.search_for_position <- false;
		}
	}
	
	bool validate_row(int row){
		loop col from: 0 to: number_of_queens-1{
			if(cell_occupied[col, row] = true){
				return false;
			}
		}
		return true; //If none of the rows are a problem we return true
	}
	
	bool validate_col(int col){
		loop row from: 0 to: number_of_queens-1{
			if(cell_occupied[col, row] = true){
				return false;
			}
		}
		return true; //If none of the columns are a problem we return true
	}
	
	bool validate_diag(int col, int row){
		//Upper diagonal above us
		int diag_col <- col + 1;
		int diag_row <- row - 1;
		loop while: diag_col < number_of_queens and diag_row >= 0{
			if(cell_occupied[diag_col, diag_row] = true){
				return false;
			}
			diag_col <- diag_col + 1;
			diag_row <- diag_row - 1;
		}
		//Upper diagonal below us
		int diag_col2 <- col - 1;
		int diag_row2 <- row + 1;
		loop while: diag_row2 < number_of_queens and diag_col2 >= 0{
			if(cell_occupied[diag_col2, diag_row2] = true){
				return false;
			}
			diag_col2 <- diag_col2 - 1;
			diag_row2 <- diag_row2 + 1;
		}
		//Lower diagonal above us
		int diag_col3 <- col - 1;
		int diag_row3 <- row - 1;
		loop while: diag_col3 >= 0 and diag_row3 >= 0{
			if(cell_occupied[diag_col3, diag_row3] = true){
				return false;
			}
			diag_col3 <- diag_col3 - 1;
			diag_row3 <- diag_row3 - 1;
		}
		//Lower diagonal below us
		int diag_col4 <- col + 1;
		int diag_row4 <- row + 1;
		loop while: diag_row4 < number_of_queens and diag_col4 < number_of_queens {
			if(cell_occupied[diag_col4, diag_row4] = true){
				return false;
			}
			diag_col4 <- diag_col4 + 1;
			diag_row4 <- diag_row4 + 1;
		}
		return true; //If none of the diagonals are a problem we return true
	}
}

experiment myExperiment type: gui
{
	output{
		display myDisplay type: opengl{
			grid chessboard lines: #black;
			species Queen aspect: base;
		}
	}
}