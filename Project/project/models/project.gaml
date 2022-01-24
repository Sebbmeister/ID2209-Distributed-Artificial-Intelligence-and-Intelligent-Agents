/**
* Name: project
* Author: Sara Moazez Gharebagh & Sebastian Lihammer
*/

model project

global{
	int happy_guests <- 0;
	int unhappy_guests <- 0;
	
	int number_of_guests <- 50;
	list<string> personality_types <- ["Party", "Neutral", "Chill"];
	list<string> diet_types <- ["Vegan", "Meat-eater"];
	
	list<Guest> list_of_guests;
	
	init{
		create Guest number: number_of_guests{
			personality_type <- personality_types[rnd(0,2)];
			diet_type <- diet_types[rnd(0,1)];
			
			add self to: list_of_guests;
		}
		create DanceFloor{
			location <- {72,50};
		}
		create FoodStand{
			location <- {10,20};
		}
		create Bar{
			location <- {10,80};
		}
		
		create happinessMeasurer{
			location <- {0,0};
		}
	}
	
	//List of guests at different location - to see which guests should be affected
	//list<Guest> danceFloorList <- [];
	//list<Guest> foodStandList <- [];
	//list<Guest> barList <- [];
}

species DanceFloor {
	aspect base {
		draw box(55.0,95.0,0.5) texture: '../images/dancefloor.jpg' ;
	}
}

species FoodStand{
	aspect base {
		rgb agentColor <- rgb("bisque");
		draw box(9.0,15.0,9.0) color: agentColor;
	}
}

species Bar{
	bool drawn <- false;
	
	aspect base {
		rgb agentColor <- rgb("chocolate");
		draw box(9.0,15.0,9.0) color: agentColor;
	}
}

species Guest skills: [fipa, moving]{
	string personality_type;
	string diet_type;
	point targetPoint <- nil;
	point danceSpot <- nil;
	
	//Attributes
	float kind;
	float chatty;
	float generous;
	
	//Needs
	float hunger <- rnd(0.0,0.5) max: 1.0 update: hunger + rnd(0.01);
	float thirst <- rnd(0.0,0.5) max: 1.0 update: thirst + rnd(0.01);
	float dance_need <- rnd(0.0,0.5) max: 1.0 update: dance_need + rnd(0.01);
	
	//Value to measure
	float happiness <- 0.5 max: 1.0 min: 0.0; //Everyone starts with 0.5 happiness
	
	//Bools
	bool hasTarget <- false; 
	bool isAngry <- false;
	
	//Personality-specific
	float makeNoise <- 0.0;
	
	init{
		self.kind <- rnd(0.0, 1.0);
		self.generous <- rnd(0.0, 1.0);
		if(self.personality_type = "Party"){
			self.chatty <- rnd(0.3, 1.0);
		}
		else{
			self.chatty <- rnd(0.0, 1.0);
		}
	}
	
	aspect base{
		if(diet_type = "Vegan"){
			draw sphere(1.3) at: location + {0,0,5} color: #lightgreen;
		}
		else if(diet_type = "Meat-eater"){
			draw sphere(1.3) at: location + {0,0,5} color: #black;
		}
		if(personality_type = "Party"){
			draw cone3D(3,6) at: location color: #hotpink;
			self.makeNoise <- self.makeNoise + rnd(0.01);
		}
		else if(personality_type = "Neutral"){
			draw cone3D(3,6) at: location color: #lemonchiffon;
			self.makeNoise <- self.makeNoise + rnd(0.005);
		}
		else if(personality_type = "Chill"){
			draw cone3D(3,6) at: location color: #lightblue;
		}
	}
	
	reflex moveToTarget when: self.targetPoint != nil
	{
		do goto target: self.targetPoint;
	}
	
	reflex wanderAround when: self.targetPoint = nil and self.hasTarget = false{
		do wander;
	}
	
	//reflex randomWalk when: time mod rnd(10,80) = 0 and self.hasTarget = false{
	//	self.targetPoint <- {rnd(5,95),rnd(5,95)};
	//	self.hasTarget <- true;
	//}
	
	reflex timeToEat when: self.hunger >= 1.0 and self.hasTarget = false{
		self.targetPoint <- {10,20};
		//do removeFromLists;
		self.hasTarget <- true;
	}
	
	reflex timeToDrink when: self.thirst >= 1.0 and self.hasTarget = false{
		self.targetPoint <- {10,80};
		//do removeFromLists;
		self.hasTarget <- true;
	}
	
	reflex timeToDance when: self.dance_need >= 1.0 and self.hasTarget = false{
		self.danceSpot <- {rnd(50,85), rnd(15,85)};
		self.targetPoint <- self.danceSpot;
		//do removeFromLists;
		self.hasTarget <- true;
	}
	/* 
	//Remove guest from list of guests at previous location
	bool removeFromLists{
		if foodStandList contains self{
			remove self from: foodStandList;
			//write("" + self + " removed itself from the food stand list");
			//write("Current food stand list:" + foodStandList);
		}
		if barList contains self{
			remove self from: barList;
			//write("" + self + " removed itself from the bar list");
			//write("Current bar list:" + barList);
		}
		if danceFloorList contains self{
			remove self from: danceFloorList;
			//write("" + self + " removed itself from the dance floor list");
			//write("Current dance floor list:" + danceFloorList);
		}
		return true;
	} */
	
	reflex getAngry when: self.happiness = 0.0{
		self.isAngry <- true;
	}
	
	reflex atTarget when: self.location = self.targetPoint and self.hasTarget = true{
		if self.location = {10,20}{
			//write("" + self + " is eating");
			//add self to: foodStandList;
			self.hunger <- 0.0;
			self.thirst <- 0.0;
			self.dance_need <- 0.0;
			if(self.makeNoise >= 1.0){
				list<Guest> nearbyGuests <- Guest at_distance 10;
				write("" + self + " is making noise at the food stand");
				if(length(nearbyGuests) > 0){
					do start_conversation with: (to :: nearbyGuests, protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "noise"]);
					write("List being sent the food stand noise message: " + nearbyGuests);
				}
				self.makeNoise <- 0.0;
			}
			list<Guest> nearbyGuests <- Guest at_distance 10;
			if(length(nearbyGuests) > 0){
				if(self.diet_type = "Meat-eater"){
					write("" + self + " is buying meat at the food stand");
					do start_conversation with: (to :: nearbyGuests, protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "meat-eating"]);
				}
				else{
					write("" + self + " is buying vegan food at the food stand");
					do start_conversation with: (to :: nearbyGuests, protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "vegan"]);
				}
			}
		}
		else if self.location = {10,80}{
			//write("" + self + " is drinking");
			//add self to: barList;
			self.thirst <- 0.0;
			self.hunger <- 0.0;
			self.dance_need <- 0.0;
			if(self.makeNoise >= 1.0){
				list<Guest> nearbyGuests <- Guest at_distance 10;
				write("" + self + " is making noise at the bar");
				if(length(nearbyGuests) > 0){
					do start_conversation with: (to :: nearbyGuests, protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "noise"]);
					write("List being sent the bar noise message: " + nearbyGuests);
				}
				self.makeNoise <- 0.0;
			}
			if(self.personality_type = "Chill" and self.happiness > 0.5){
				list<Guest> nearbyGuests <- Guest at_distance 10;
				if(length(nearbyGuests) > 0){
					do start_conversation with: (to :: [nearbyGuests[0]], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "ask to drink beer and chill"]);
					write("" + self + " is asking " + nearbyGuests[0] + " to drink some beer and chill with them");
				}
			}
			else if(self.generous >= 0.5 and self.happiness >= 0.5){
				list<Guest> nearbyGuests <- Guest at_distance 10;
				if(length(nearbyGuests) > 0){
					do start_conversation with: (to :: [nearbyGuests[0]], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "drink"]);
					write("" + self + " is offering to buy " + nearbyGuests[0] + " a drink");
				}
			}
		}
		else if self.location = self.danceSpot{	
			//write("" + self + " is dancing");
			//add self to: danceFloorList;
			self.danceSpot <- nil;
			self.dance_need <- 0.0;
			self.thirst <- 0.0;
			self.hunger <- 0.0;
		}
		self.targetPoint <- nil;
		self.hasTarget <- false;
		
		if(self.personality_type = "Neutral" and self.chatty >= 0.5){
			list<Guest> nearbyGuests <- Guest at_distance 10;
			if(length(nearbyGuests) > 0){
				write("" + self + " asked " + nearbyGuests[0] + " if they want to grab a snack at the food stand");
				do start_conversation with: (to :: [nearbyGuests[0]], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "grab a snack"]);
			}
		}
		if(self.chatty >= 0.5 and self.happiness >= 0.5){
			list<Guest> nearbyGuests <- Guest at_distance 10;
			if(length(nearbyGuests) > 0){
				if(self.personality_type = "Party"){
					write("" + self + " asked " + nearbyGuests[0] + " to dance");
					do start_conversation with: (to :: [nearbyGuests[0]], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "ask to dance"]);
				}
				else{
					write("" + self + " talked to " + nearbyGuests[0]);
					do start_conversation with: (to :: [nearbyGuests[0]], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "start chatting"]);
				}	
			}
		}
	}
	
	reflex read_message when: !(empty(informs)){
		message msg <- (informs at 0);
		list<unknown> message_list <- msg.contents;
		string messagecontent <- string(message_list[1]);
		Guest messageSender <- Guest(message_list[0]);
		
		if(messagecontent = "noise" and self != messageSender){
			if(self.personality_type = "Chill"){
				write("" + self + " did not like the noise made by " + messageSender);
				self.happiness <- self.happiness - 0.3;
			}
			if(self.personality_type = "Party"){
				write("" + self + " liked the noise made by " + messageSender);
				self.happiness <- self.happiness + 0.1;
			}
			if(self.personality_type = "Neutral"){
				if(self.happiness >= 0.5){
					write("" + self + " liked the noise made by " + messageSender);
					self.happiness <- self.happiness + 0.1;
				}
				else{
					write("" + self + " did not like the noise made by " + messageSender);
					self.happiness <- self.happiness - 0.3;
				}
			}
			if(self.isAngry){
				write("" + self + " is scolding the noise-maker");
				self.isAngry <- false;
				self.happiness <- 0.2;
				//Guest is scolding the noise-maker
				do start_conversation with: (to :: [messageSender], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "scold"]);
			}
		}
		if(messagecontent = "drink"){
			if(self.happiness >= 0.5){
				write("" + self + " accepted the drink from " + messageSender);
				self.happiness <- self.happiness + 0.1;
				messageSender.happiness <- messageSender.happiness + 0.1;
			}
			if(self.isAngry){
				write("" + self + " got mad at the drink offer from " + messageSender);
				do start_conversation with: (to :: [messageSender], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "scold"]);
				self.isAngry <- false;
				self.happiness <- 0.2;
			}
			else if(self.happiness < 0.5){
				write("" + self + " declined the drink from " + messageSender);
				messageSender.happiness <- messageSender.happiness - 0.2;
			}
		}
		if(messagecontent = "start chatting"){
			if(self.chatty >= 0.5 and self.happiness >= 0.5){
				do start_conversation with: (to :: [messageSender], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "chat"]);
				self.happiness <- self.happiness + 0.1;
			}
			else if(self.isAngry){
				write("" + self + " got mad that " + messageSender + " talked to them");
				do start_conversation with: (to :: [messageSender], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "scold"]);
				self.isAngry <- false;
				self.happiness <- 0.2;
			}
			else if(self.chatty < 0.5 or self.happiness < 0.5){
				write("" + self + " ignored " + messageSender);
				messageSender.happiness <- messageSender.happiness - 0.3;
			}
		}
		if(messagecontent = "ask to drink beer and chill"){
			if(self.personality_type = "Chill" or happiness >= 0.5 and !(self.personality_type = "Party")){
				write("" + self + " agreed to chill have a beer with " + messageSender);
				self.thirst <- 0.0;
				messageSender.thirst <- 0.0;
				self.happiness <- self.happiness + 0.2;
				messageSender.happiness <- messageSender.happiness + 0.2;
			}
			else if(self.isAngry){
				write("" + self + " does not to chill and have a beer with " + messageSender + " right now");
				do start_conversation with: (to :: [messageSender], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "scold"]);
				self.isAngry <- false;
				self.happiness <- 0.2;
			}
			else{
				write("" + self + " ignored " + messageSender);
				messageSender.happiness <- messageSender.happiness - 0.2;
			}
		}
		if(messagecontent = "grab a snack"){
			if(self.happiness >= 0.5 or self.hunger < 0.3){
				write("" + self + " agreed to grab a snack with " + messageSender);
				self.hasTarget <- true;
				self.targetPoint <- {10,20};
				messageSender.hasTarget <- true;
				messageSender.targetPoint <- {10,20};
				self.happiness <- self.happiness + 0.1;
				messageSender.happiness <- messageSender.happiness + 0.1;
			}
			else if(self.isAngry){
				write("" + self + " does not want to grab a snack with " + messageSender + " right now");
				do start_conversation with: (to :: [messageSender], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "scold"]);
				self.isAngry <- false;
				self.happiness <- 0.2;
			}
			else{
				write("" + self + " ignored " + messageSender);
				messageSender.happiness <- messageSender.happiness - 0.2;
			}
		}
		if(messagecontent = "ask to dance"){
			if(self.personality_type = "Party" or happiness >= 0.5 and !(self.personality_type = "Chill")){
				write("" + self + " agreed to dance with " + messageSender);
				point newDanceSpot <- {rnd(50,85), rnd(15,85)};
				self.hasTarget <- true;
				self.targetPoint <- newDanceSpot;
				self.danceSpot <- newDanceSpot;
				messageSender.hasTarget <- true;
				messageSender.danceSpot <- newDanceSpot;
				messageSender.targetPoint <- newDanceSpot;
				self.happiness <- self.happiness + 0.2;
				messageSender.happiness <- messageSender.happiness + 0.2;
			}
			else if(self.isAngry){
				write("" + self + " does not want to dance with " + messageSender + " right now");
				do start_conversation with: (to :: [messageSender], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "scold"]);
				self.isAngry <- false;
				self.happiness <- 0.2;
			}
			else{
				write("" + self + " ignored " + messageSender);
				messageSender.happiness <- messageSender.happiness - 0.2;
			}
		}
		if(messagecontent = "chat"){
			self.happiness <- self.happiness + 0.1;
		}
		if(messagecontent = "scold" and self != messageSender){
			write("" + self + " was scolded");
			self.happiness <- self.happiness - 0.3;
		}
		if(messagecontent = "inform" and self != messageSender){
			if(self.happiness >= 0.5){
				write("" + self + " is considering going vegan");
				self.happiness <- self.happiness + 0.1;
			}
			else{
				write("" + self + " does not want to hear about animals right now");
				self.happiness <- self.happiness - 0.1;
			}
		}
		if(messagecontent = "meat-eating" and self != messageSender){
			if(self.diet_type = "Vegan"){
				if(self.isAngry = true and self.kind < 0.5){
					write("" + self + " is scolding the meat-eater");
					do start_conversation with: (to :: [messageSender], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "scold"]);
					self.isAngry <- false;
					self.happiness <- 0.2;
				}
				else if(self.happiness <= 0.5 and self.chatty >= 0.5){
					write("" + self + " is informing the meat-eater about animals");
					do start_conversation with: (to :: [messageSender], protocol :: 'fipa-request', performative :: 'inform', contents :: [self, "inform"]);
					self.happiness <- self.happiness + 0.1;
				}
			}
		}
		if(messagecontent = "vegan" and self != messageSender){
			if(self.diet_type = "Vegan"){
				write("" + self + " likes to see people buying vegan food");
				self.happiness <- self.happiness + 0.1;
			}
		}
	}
}

species happinessMeasurer{
	reflex measureHappiness when: every(100#cycles){
		happy_guests <- 0;
		unhappy_guests <- 0;
		loop guest over: list_of_guests{
			if(guest.happiness >= 0.5){
				happy_guests <- happy_guests + 1;
			}
			else{
				unhappy_guests <- unhappy_guests + 1;
			}
		}
	}
}

experiment myExperiment type: gui
{
	output{
		display myDisplay type: opengl{
			image '../images/floor.jpg' ;
			species Guest aspect:base;
			species DanceFloor aspect:base;
			species FoodStand aspect:base;
			species Bar aspect:base;
			species happinessMeasurer;
		}
		display Chart refresh: every(100#cycles) {
			chart "Happiness and unhappiness" type: pie { 
				data "Happy people" value: happy_guests color: #green;
				data "Unhappy people" value: unhappy_guests color: #red;
			}
		}
	}
}