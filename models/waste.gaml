/**
* Name: waste 
* Authors: DinhAnh, MinhLong
* Tags: 
*/


model waste

global {
	file shape_file_buildings <- file("../includes/building.shp");
    file shape_file_roads <- file("../includes/road.shp");
    
    geometry shape <- envelope(envelope(shape_file_buildings) 
		union envelope(shape_file_roads)
	);
	
	float micro <- 0.1;
	float threshold_d <- 0.1;
			
	string ACTION_SUPPORT <- "support";
	string ACTION_AWARE <- "aware";
	string ACTION_RECYCLE <- "recycle";
		
	string chosen_btn_action <- "";
	
	init {
		create building from:shape_file_buildings;
		
		create road from: shape_file_roads;
		
		do create_button(#cyan, ACTION_SUPPORT, {40, 60});
		do create_button(#seagreen, ACTION_AWARE, {40, 100});
		do create_button(#slategrey, ACTION_RECYCLE, {40, 140});
		
		create Inhabitant number: 100 {
			location <- any_location_in(one_of(building));
		}
		
		ask Inhabitant {
			friends <- Inhabitant closest_to(self, max_friend);
		}
	}
	
	action create_button(rgb col, string action_n, point loc) {
		create button {
			color <- col;
			btn_action <- action_n;
			location <- loc;
		}
	}
	
	action support {
		write "support";
		list<Inhabitant> pp <- rnd(1, length(Inhabitant)) among Inhabitant;
		loop p over: pp {
			p.financial_incentive <- p.financial_incentive + 0.1;
		}
	}

	action aware {
		write "aware";
		list<Inhabitant> pp <- rnd(1, length(Inhabitant)) among Inhabitant;
		loop p over: pp {
			p.opinion <- p.opinion + 0.1;
		}
	}

	action recycle {
		write "reycle";
		list<Inhabitant> pp <- rnd(1, length(Inhabitant)) among Inhabitant;
		loop p over: pp {
			p.easy_recycle <- p.easy_recycle + 0.1;
		}
	}
	
	action activate_button{
		button b <- first(button overlapping #user_location);
		if b != nil{
			if (b.btn_action = chosen_btn_action){
				chosen_btn_action <- "";
			}else{
				chosen_btn_action <- b.btn_action;
			}
		}
	}

	reflex do_gorvernment {
		if chosen_btn_action != "" {
			if chosen_btn_action = ACTION_SUPPORT {
				do support;
				chosen_btn_action <- "";
			} else if (chosen_btn_action = ACTION_AWARE) {
				do aware;
				chosen_btn_action <- "";
			} else if (chosen_btn_action = ACTION_RECYCLE) {
				do recycle;
				chosen_btn_action <- "";
			}
		}
	}
}

species building {
    string type; 
    rgb color <- #gray  ;
    
    aspect looks {
    	draw shape color: color ;
    }
}

species road  {
    rgb color <- #black ;
    
    aspect looks {
    	draw shape color: color ;
    }
}

species button{
	rgb color;
	geometry shape <- square(20);
	string btn_action;
	
	aspect default{
		draw shape color: color;
		draw around(3.0, shape) color: (chosen_btn_action = btn_action)? #red: #black;
	}
}
species Inhabitant {
	rgb color;
	float opinion;
	int max_friend;
	list<Inhabitant> friends;
	
	float financial_incentive;
	float easy_recycle;
	float adoption_threshold;
	bool want_sort;
	
	init {
		opinion <- rnd(0.0, 1.0);
		max_friend <- rnd(0, 10);
		
		financial_incentive <- 0.0;
		easy_recycle <- 0.0;
		adoption_threshold <- rnd(0.6, 0.9);
		want_sort <- false;
	}	
	
	aspect looks {
//		draw circle(5) color: rgb(255*opinion, 99, 132); // black, blue, purple, pink
		draw circle(5) color: want_sort ? #green : #red;
	}
	
	reflex diffuseOpinion {
		if(max_friend > 0) {
			Inhabitant friend <- friends[rnd(0, max_friend-1)];
			if(abs(opinion - friend.opinion) < threshold_d){
				float temp <- opinion;
				opinion <- opinion + micro * (friend.opinion - opinion);
				friend.opinion <- friend.opinion + micro * (temp - friend.opinion);
			} 
		}
	}
	
	reflex survey when: cycle mod 7 = 0 {
		if (opinion + financial_incentive + easy_recycle > adoption_threshold) {
			want_sort <- true;
		} else {
			want_sort <- false;
		}
		
	}
}

//species Government {
//	action support {
//		list<Inhabitant> pp <- rnd(1, length(Inhabitant)) among Inhabitant;
//		loop p over: pp {
//			p.financial_incentive <- p.financial_incentive + 0.1;
//		}
//	}
//	
//	action aware {
//		list<Inhabitant> pp <- rnd(1, length(Inhabitant)) among Inhabitant;
//		loop p over: pp {
//			p.opinion <- p.opinion + 0.1;
//		}
//	}
//	
//	action recycle {
//		list<Inhabitant> pp <- rnd(1, length(Inhabitant)) among Inhabitant;
//		loop p over: pp {
//			p.opinion <- p.opinion + 0.1;
//		}
//	}
//}

experiment e type: gui {
	output {
		display d {
			species button;
			species building aspect: looks;
			species road aspect: looks;
			species Inhabitant aspect: looks;
			event mouse_down action: activate_button;
		}
		monitor avg_opinion value: mean(Inhabitant collect(each.opinion));
		display pie refresh: every(7#cycles){
			chart "Want sort vs Not Want" type: pie style: exploded size: {1, 0.5} position: {0, 0.5} {
				data "Want Sort" value: Inhabitant count(each.want_sort=true) color: #green;
				data "Not Want" value: Inhabitant count(each.want_sort=false) color: #red;
			}
		}
	}
}

experiment batch_experiment type: batch repeat: 1 keep_seed: true until: (time > 1000) {
	parameter 'Government decisions:' var: chosen_btn_action 
	    among: [ ACTION_SUPPORT, ACTION_AWARE, ACTION_RECYCLE ];
		permanent {
			display Comparison {
				chart "Number of people who want to sort" type: series {
					data "Number of people who want to sort" 
					    value: Inhabitant count (each.want_sort=true) style: spline color: #blue ;
				}
			}	
	}
}