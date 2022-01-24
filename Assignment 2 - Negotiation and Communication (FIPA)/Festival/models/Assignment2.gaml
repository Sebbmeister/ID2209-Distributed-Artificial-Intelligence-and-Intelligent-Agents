/**
* Name: Assignment2
* Author: Sara Moazez Gharebagh and Sebastian Lihammer
*/

model Assignment2

global{
	int nPeople <- 40;
	int nInfoCenters <- 2;
	int nAuctioneers <- 1;

	init{
		create FestivalGuest number: nPeople
		{
			chosenInfoCenter <- rnd(1,2);
		}
		
		create FoodStore{location <- {10,90};}
		create FoodStore{location <- {10,10};}
		create FoodStore{location <- {90,10};}
		create FoodStore{location <- {90,90};}
		create DrinkStore{location <- {40,50};}
		create DrinkStore{location <- {60,50};}
		create Auctioneer;
		
		create InfoCenter1
		{
			location <- {10,50};
			drinkstoreloc <- {40,50};
			foodstore1loc <- {10,90};
			foodstore2loc <- {10,10};
		}
		create InfoCenter2
		{
			location <- {90,50};
			drinkstoreloc <- {60,50};
			foodstore1loc <- {90,90};
			foodstore2loc <- {90,10};
		}
	}	
}

species Auctioneer skills: [fipa]{
	
	list<FestivalGuest> attendees <- [];
	int current_price <- rnd(300,1000);
	int min_price <- current_price - rnd(100, 500) min: 100;
	//int current_price <- min_price + rnd(100,500) min: 0;
	bool auction <- false;
	FestivalGuest winning_guest; 
	bool auction_winner <- false;
	bool update <- false;
	bool check <- false;
	aspect base{
		rgb agentColor <- rgb("brown");
		draw squircle(4,4) color: agentColor;
	}
	
	reflex initiate_auction when: length(attendees) > 3 and auction = false{
		write("The participants are: " + attendees);
		auction <- true;
		check <- true;
		write("The auction has begun, starting price is: " + current_price);
		write("Minimum price is: " + min_price);
		
		loop p over: attendees
		{
			//inform start of auction
			do start_conversation (to :: [p], protocol :: 'fipa-request', performative :: 'inform', contents :: ['The auction will now begin']);
			
		}
	}
	
	reflex send_message when: auction = true and auction_winner = false and check = true{
		//call for proposals
		do start_conversation with: (to :: attendees, protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [current_price]);
		check <-false; 
	}
	
	reflex read_message when: (auction = true and !empty(proposes)){
		loop p over: proposes{
			list<unknown> propose_list <- p.contents;
				if (propose_list[0] = true){
					do accept_proposal with: [message :: p, contents :: ['Participants offer accepted']];
					winning_guest <- p.sender;
					auction_winner <- true;
					auction <- false;
					update <- false;
					write("Item sold to " + winning_guest + " auction is now over");
					break;
				}
		}
		if(auction_winner = false){
			update <- true;
		}
	}
	
	reflex update_price when: (update = true and auction_winner = false){
		current_price <- current_price - rnd(10,50);
		write ("Updating price, current price is now: " + current_price);
		if(current_price < min_price){
			auction <- false;
			loop p over: attendees{
				//inform
				do start_conversation (to :: [p], protocol :: 'fipa-request', performative :: 'inform', contents :: ['The auction is cancelled']);
			}
			attendees <- [];
			write ("Auction cancelled, item not sold");
		}
		check <- true;
		update <- false;
	}
	
	reflex found_winner when: auction_winner = true{
		loop p over: attendees{
			//inform the participants of the winner
			do start_conversation (to :: [p], protocol :: 'fipa-request', performative :: 'inform', contents :: ['The auction is over']);
		}
		attendees <- [];
	} 

}


/* FestivalGuest uses the methods of moving */
species FestivalGuest skills: [fipa,moving]
{
	int participant_in_auction <- rnd(1,5);
	int chosenInfoCenter; //the info center we will go to
	float hunger <- rnd(10) max: 10 update: hunger+rnd(0.01);
	float thirst <- rnd(10) max: 10 update: thirst+rnd(0.01);
	bool knowledgeOfStore <- false;
	bool decidedPrice <- false;
	point auctionlocation;
	int budget; 
	bool in_auction <- false;
	bool want_to_buy <- false;
	bool go <- false;
	
	/* color and shape */
	aspect base {
		rgb agentColor <- rgb("green");
		if (hunger > 5 and thirst > 5) {
			agentColor <- rgb("pink");
		}
		else if (thirst > 5) {
			agentColor <- rgb("blue");
		}
		else if (hunger > 5) {
			agentColor <- rgb("purple");
		}
		draw circle(1) color: agentColor;
	}
	reflex go_to_auction when: (participant_in_auction = 3 and go = false){
		hunger <- 0.0;
		thirst <- 0.0; 
		ask Auctioneer{
			myself.auctionlocation <- self.location;
		}
		targetPoint <- auctionlocation;
		if(location = auctionlocation){
			ask Auctioneer{
				if(auction = false){
					add myself to: attendees;
					myself.go <- true;
				}
				else{
					myself.targetPoint <- nil;
					myself.participant_in_auction <- 0;
				}
				
			}
		}
		
	}
	
	reflex read_message when: (!empty(cfps) and participant_in_auction = 3){
		message price_message <- cfps at 0;
		//list<unknown> price_list <- price_message.contents;
		list<unknown> price_messages <- price_message.contents;
		int price <- int(price_messages[0]);
		if(!(self.decidedPrice)){
			self.budget <- price - rnd(100, 500);
			if(self.budget <= 0){
				self.budget <- 100; 
			}
			write("" + self + " ready to pay: " + self.budget);
			self.decidedPrice <- true;
		}
		if(self.budget >= price){
			self.want_to_buy <- true;
		}
		//propose an offer
		do propose with: (message: price_message, contents: [self.want_to_buy]);
	}
	
	point targetPoint <- nil;
	reflex beIdle when: targetPoint = nil
	{
		do wander;
	}
	
	/* If targetPoint is not nil (we have a target to go to) we go there */
	reflex moveToTarget when: targetPoint != nil
	{
		do goto target:targetPoint;
	}
	
	//reflex moveToInfoCenter when: (isThirsty or isHungry) and targetPoint = nil {
	reflex moveToInfoCenter when: (hunger > 5 or thirst > 5) and knowledgeOfStore = false {
		//write("Guest moving to info center");
		if(chosenInfoCenter = 1){
			targetPoint <- {10,50};
		}
		else if(chosenInfoCenter = 2)
		{
			targetPoint <- {90,50};
		}
		if(location = {10,50})
		{
			//write("Guest at info center 1");
			if(thirst > 5){
				ask InfoCenter1{
					//write("Guest asks info center 1 for drink store");
					myself.targetPoint <- drinkstoreloc;
					myself.knowledgeOfStore <- true;
					//write("Guest moving to drink store 1");
				}
			}
			if(hunger > 5){
				int randomNumber <- rnd(1,2);
				if(randomNumber = 1){
					ask InfoCenter1{
						//write("Guest asks info center 1 for food store");
						myself.targetPoint <- foodstore1loc;
						myself.knowledgeOfStore <- true;
						//write("Guest moving to food store 1");
					}
				}
				if(randomNumber = 2){
					ask InfoCenter1{
						//write("Guest asks info center 1 for food store");
						myself.targetPoint <- foodstore2loc;
						myself.knowledgeOfStore <- true;
						//write("Guest moving to food store 2");
					}
				}
			}
		}
		if(location = {90,50})
		{
			//write("Guest at info center 2");
			if(thirst > 5){
				ask InfoCenter2{
					//write("Guest asks info center 2 for drink store");
					myself.targetPoint <- drinkstoreloc;
					myself.knowledgeOfStore <- true;
					//write("Guest moving to drink store 2");
				}
			}
			if(hunger > 5){
				int randomNumber <- rnd(1,2);
				if(randomNumber = 1){
					ask InfoCenter2{
						//write("Guest asks info center 2 for food store");
						myself.targetPoint <- foodstore1loc;
						myself.knowledgeOfStore <- true;
						//write("Guest moving to food store 3");
					}
				}
				if(randomNumber = 2){
					ask InfoCenter2{
						//write("Guest asks info center 2 for food store");
						myself.targetPoint <- foodstore2loc;
						myself.knowledgeOfStore <- true;
						//write("Guest moving to food store 4");
					}
				}
			}
		}
	}
	
	reflex goToStore when: knowledgeOfStore = true{
		do goto target:targetPoint;
	}
	
	
	reflex getDrink when: thirst > 5{
		if(location = {40,50}){
			//write("Guest at drink store 1");
			thirst <- 0.0;
			knowledgeOfStore <- false;
			targetPoint <- nil;
			//write("Guest no longer thirsty");
		}
		if(location = {60,50}){
			//write("Guest at drink store 2");
			thirst <- 0.0;
			knowledgeOfStore <- false;
			targetPoint <- nil;
			//write("Guest no longer thirsty");
		}
	}
	reflex getFood when: hunger > 5{
		if(location = {10,90}){
			//write("Guest at food store 1");
			hunger <- 0.0;
			knowledgeOfStore <- false;
			targetPoint <- nil;
			//write("Guest no longer hungry");
		}
		if(location = {10,10}){
			//write("Guest at food store 2");
			hunger <- 0.0;
			knowledgeOfStore <- false;
			targetPoint <- nil;
			//write("Guest no longer hungry");
		}
		if(location = {90,10}){
			//write("Guest at food store 4");
			hunger <- 0.0;
			knowledgeOfStore <- false;
			targetPoint <- nil;
			//write("Guest no longer hungry");
		}
		if(location = {90,90}){
			//write("Guest at food store 3");
			hunger <- 0.0;
			knowledgeOfStore <- false;
			targetPoint <- nil;
			//write("Guest no longer hungry");
		}
	}
}

species FoodStore {
	/* color and shape */
	aspect base {
		rgb agentColor <- rgb("black");
		draw square(4) color: agentColor;
	}
}

species DrinkStore {
	/* color and shape */
	aspect base {
		rgb agentColor <- rgb("grey");
		draw square(4) color: agentColor;
	}
}

species InfoCenter1 {
	//Food stores
	point foodstore1loc;
	point foodstore2loc;
	//Drink stores
	point drinkstoreloc;
	
	/* color and shape */
	aspect base {
		rgb agentColor <- rgb("orange");
		draw triangle(6) color: agentColor;
	}
}

species InfoCenter2 {
	//Food stores
	point foodstore1loc;
	point foodstore2loc;
	//Drink stores
	point drinkstoreloc;
	
	/* color and shape */
	aspect base {
		rgb agentColor <- rgb("orange");
		draw triangle(6) color: agentColor;
	}
}

experiment myExperiment type:gui {
	output {
		display myDisplay {
			//Display the species with the created aspects
			species FestivalGuest aspect:base;
			species FoodStore aspect:base;
			species DrinkStore aspect:base;
			species InfoCenter1 aspect:base;
			species InfoCenter2 aspect:base;
			species Auctioneer aspect:base;
		}
	}
}

