/**
* Name: project
* Author: Sara Moazez Gharebagh & Sebastian Lihammer
*/


model project

global{
	int number_of_guests <- 50;
	list<string> personality_types <- ["Extrovert", "Ambivert", "Introvert"];
	list<string> diet_types <- ["Vegan", "Meat-eater"];
	init{
		create Guest number: number_of_guests{
			personality_type <- personality_types[rnd(0,2)];
			diet_type <- diet_types[rnd(0,1)];
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
	}
	
}

species DanceFloor {
	aspect base {
		//rgb agentColor <- rgb("black");
		draw box(55.0,95.0,0.5) texture: '../images/dancefloor.jpg' ;
	}
}

species FoodStand{
	aspect base {
		rgb agentColor <- rgb("black");
		draw box(9.0,15.0,9.0) color: agentColor;
	}
}

species Bar{
	aspect base {
		rgb agentColor <- rgb("black");
		draw box(9.0,15.0,9.0) color: agentColor;
		draw "Bar" at: location + {0,0,0.1} color:  #white font: font('Default', 12, #bold);
	}
}

species Guest skills: [fipa, moving]{
	string personality_type;
	string diet_type;
	
	//Attributes
	float kind;
	float chatty;
	float generous;
	
	//Value to measure
	float happiness <- 0.5; //Everyone starts with 0.5 happiness
	
	init{
		self.kind <- rnd(0.0, 1.0);
		self.generous <- rnd(0.0, 1.0);
		self.chatty <- rnd(0.0, 1.0);
	}
	
	aspect base{
		if(diet_type = "Vegan"){
			draw sphere(1.3) at: location + {0,0,5} color: #lightgreen;
		}
		else if(diet_type = "Meat-eater"){
			draw sphere(1.3) at: location + {0,0,5} color: #black;
		}
		if(personality_type = "Extrovert"){
			draw cone3D(3,6) at: location color: #hotpink;
		}
		else if(personality_type = "Ambivert"){
			draw cone3D(3,6) at: location color: #lemonchiffon;
		}
		else if(personality_type = "Introvert"){
			draw cone3D(3,6) at: location color: #lightblue;
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
		}
	}
}