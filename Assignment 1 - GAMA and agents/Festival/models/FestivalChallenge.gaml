/**
* Name: FestivalChallenge
* Based on the internal empty template. 
* Author: Sara Moazez Gharebagh & Sebastian Lihammer
* Tags: 
*/

model FestivalChallenge

global{
	int nPeople <- 40;
	int nBad <- rnd(1,5);
	int nSecurity <- 1;
	int nInfoCenters <- 2;
	//int nStores <- 6;

	init{
		create BadGuest number: nBad;
		create SecurityGuard number: nSecurity;
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

/* FestivalGuest uses the methods of moving */
species FestivalGuest skills: [moving]
{
	int chosenInfoCenter; //the info center we will go to
	float hunger <- rnd(10) max: 10 update: hunger+rnd(0.01);
	float thirst <- rnd(10) max: 10 update: thirst+rnd(0.01);
	bool knowledgeOfStore <- false;
	
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

species BadGuest skills: [moving]{
	float wantToSteal <- rnd(5) max: 10 update: wantToSteal+rnd(0.05);
	int randomNum <- rnd(1,2);
	
	aspect base {
		rgb agentColor <- rgb("red");
		draw circle(1) color: agentColor;
	}
	
	point targetPoint <- nil;
	reflex beIdle when: targetPoint = nil
	{
		do wander;
	}
	
	reflex moveToTarget when: targetPoint != nil
	{
		do goto target:targetPoint;
	}
	
	reflex goToInfoCenter when: wantToSteal > 6{
		if (randomNum = 1){
			targetPoint <- {10,50};
			do goto target:targetPoint;
			if(location = {10,50}){
				ask InfoCenter1{
					SecurityGuard sendloc <- self.seenBadGuest(myself);
				}
				write("Bad guest behaving badly at info center 1");
				wantToSteal <- 0.0;
				targetPoint <- nil;
			}
		}
		if (randomNum = 2){
			targetPoint <- {90,50};
			do goto target:targetPoint;
			if(location = {90,50}){
				ask InfoCenter2{
					SecurityGuard sendloc <- self.seenBadGuest(myself);
				}
				write("Bad guest behaving badly at info center 2");
				wantToSteal <- 0.0;
				targetPoint <- nil;
			}
		}
	}
}

species SecurityGuard skills: [moving]{
	list<BadGuest> badGuests;

	aspect base {
		rgb agentColor <- rgb("black");
		draw circle(1.5) color: agentColor;
	}
	
	point targetPoint <- nil;
	reflex beIdle when: targetPoint = nil
	{
		do wander;
	}
	
	reflex findBadGuests when: !empty(badGuests){
		BadGuest targetGuest <- badGuests[0];
		targetPoint <- targetGuest.location;
		write("Tracking down bad guest");
		do goto target:targetPoint;
		
		if(location = targetPoint){
			ask targetGuest{
				write("Bad guest killed");
				remove item: targetGuest from: myself.badGuests;
				do die;
			}
		}
	}
	
	reflex noBad when: empty(badGuests){
		targetPoint <- nil;
	}
	
	reflex moveToTarget when: targetPoint != nil
	{
		do goto target:targetPoint;
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
	
	action seenBadGuest(BadGuest bad){
		write("Info center 1 informing security guard of bad guest");
		ask SecurityGuard{
			add bad to: badGuests;
		}
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
	
	action seenBadGuest(BadGuest bad){
		write("Info center 2 informing security guard of bad guest");
		ask SecurityGuard{
			add bad to: badGuests;
		}
	}
}

experiment myExperiment type:gui {
	output {
		display myDisplay {
			//Display the species with the created aspects
			species FestivalGuest aspect:base;
			species SecurityGuard aspect:base;
			species BadGuest aspect:base;
			species FoodStore aspect:base;
			species DrinkStore aspect:base;
			species InfoCenter1 aspect:base;
			species InfoCenter2 aspect:base;
		}
	}
}