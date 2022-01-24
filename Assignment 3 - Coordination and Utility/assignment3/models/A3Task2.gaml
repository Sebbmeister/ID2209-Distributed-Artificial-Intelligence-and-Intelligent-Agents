/**
* Name: A3Task2
* Author: Sara Moazez Gharebagh and Sebastian Lihammer
*/


model A3Task2

global{
	int number_of_guests <- 10;
	list<Guest> guests <- [];
	init{
		create Guest number: number_of_guests{
			artist_fame <- rnd(10) / 10;
			artist_skill <- rnd(10) / 10;
			sound_quality <- rnd(10) / 10;
			show_quality <- rnd(10) / 10;
			show_vibe <- rnd(10) / 10;
			dj_quality <- rnd(10) / 10;
			add self to: guests;
		}
		
		create Stage{
			location <- {50,90};
		}
		
		create Stage{
			location <- {50,10};
		}
		
		create Stage{
			location <- {10,50};
		}
		
		create Stage{
			location <- {90,50};
		}
	}
}

species Guest skills: [fipa, moving]{
	//Attributes
	float artist_fame;
	float artist_skill;
	float sound_quality;
	float show_quality;
	float show_vibe;
	float dj_quality;
	//Other
	float utility_value <- 0.0; //Current utility value
	point targetPoint <- nil;
	Stage current_stage <- nil;
	bool has_said_preferences <- false;
	
	aspect base{
		draw cone3D(1.3,1.9) at: location color: #hotpink;
		draw sphere(0.7) at: location + {0,0,1.6} color: #hotpink;
		if(self.has_said_preferences = false){
			write("" + self + " has preferences: [" + artist_fame + "," + artist_skill + "," + sound_quality + "," + show_quality + "," + show_vibe + "," + dj_quality + "]");
			self.has_said_preferences <- true;
		}
	}
	
	reflex moveToTarget when: self.targetPoint != nil
	{
		do goto target: self.targetPoint;
	}
	
	reflex read_message when: !(empty(informs)){
		//write("" + self + " has received a message");
		message msg <- (informs at 0);
		list<unknown> message_list <- msg.contents;
		Stage sending_stage <- Stage(message_list[0]);		
		
		if(self.current_stage = sending_stage){
			self.utility_value <- 0.0;
		}
		
		float temp_utility_value <- self.utility_value;
		
		list<float> stage_attributes <- message_list[1];
		
		//Check the utility
		float stage_utility <- (artist_fame * stage_attributes[0]) + (artist_skill * stage_attributes[1]) + (sound_quality * stage_attributes[2]) 
								+ (show_quality * stage_attributes[3]) + (show_vibe * stage_attributes[4]) + (dj_quality * stage_attributes[5]);
		
		if(stage_utility > self.utility_value){
			write("" + self + " is changing stage to " + sending_stage + ". Previous utility value: " + temp_utility_value +  " New utility value: " + stage_utility);
			self.utility_value <- stage_utility;
			self.targetPoint <- sending_stage.location;
			self.current_stage <- sending_stage;
		}
	}
}

species Stage skills: [fipa]{
	//Attributes
	float artist_fame;
	float artist_skill;
	float sound_quality;
	float show_quality;
	float show_vibe;
	float dj_quality;
	//Other
	int changing_time;
	
	init{
		//Initialize a random first artist
		artist_fame <- rnd(10) / 10;
		artist_skill <- rnd(10) / 10;
		sound_quality <- rnd(10) / 10;
		show_quality <- rnd(10) / 10;
		show_vibe <- rnd(10) / 10;
		dj_quality <- rnd(10) / 10;
		changing_time <- rnd(60,120);
		write("" + self + " putting on a show: [" + artist_fame + "," + artist_skill + "," + sound_quality + "," + show_quality + "," + show_vibe + "," + dj_quality + "]");
	}
	
	aspect base {
		rgb agentColor <- rgb("black");
		draw box(9.0,10.0,2.5) color: agentColor;
	}
	
	//Welcome a new artist up on the stage
	reflex newArtist when: time mod changing_time = 0{
		artist_fame <- rnd(10) / 10;
		artist_skill <- rnd(10) / 10;
		sound_quality <- rnd(10) / 10;
		show_quality <- rnd(10) / 10;
		show_vibe <- rnd(10) / 10;
		dj_quality <- rnd(10) / 10;
		changing_time <- rnd(60,120);
		do start_conversation with: (to :: guests, protocol :: 'fipa-request', performative :: 'inform', contents :: [self, [artist_fame, artist_skill, sound_quality, show_quality, show_vibe, dj_quality]]);
		write("" + self + " putting on a show: [" + artist_fame + "," + artist_skill + "," + sound_quality + "," + show_quality + "," + show_vibe + "," + dj_quality + "]");
	}
}

experiment myExperiment type: gui
{
	output{
		display myDisplay type: opengl{
			image '../images/grass.jpg' ;
			species Stage aspect:base;
			species Guest aspect:base;
		}
	}
}