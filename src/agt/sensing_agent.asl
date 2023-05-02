// sensing agent


/* Initial beliefs and rules */
has_plans_for(G):-
	role_mission(R,_,M) &
	mission_goal(M,G).

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : true <-
	.print("Hello world").

+new_gr(OrgName, GroupName) <- 	
	// Join the workspace
	.print("Received notification of new group: ", GroupName)
	joinWorkspace(OrgName, WspId)
	.print("Joined workspace ", OrgName)

	// Focus on the org and group artifacts
	lookupArtifact(OrgName, OrgArtId)[wid(WspId)]
	focus(OrgArtId)[wid(WspId)]
	
	lookupArtifact(GroupName, GrArtId)[wid(WspId)]
	focus(GrArtId)[wid(WspId)]

	// If the agent does have plan for the goal read_temperature and there is not enough players yet,
	// the agent will adopt the role temperature_reader
	if(has_plans_for(read_temperature)) {
		if(not has_enough_players_for(temperature_reader)){
			adoptRole(temperature_reader)[artifact_id(GrArtId)]
			.print("Joined ", GroupName, " in ", GroupName, " as temperature_reader")
		} else {
			.print("There are enough temperature readers already!")
		}
	} else {
		.print("I do not have plans for temperature reader.")
	}.

/* 
 * Plan for reacting to the addition of the goal !read_temperature
 * Triggering event: addition of goal !read_temperature
 * Context: true (the plan is always applicable)
 * Body: reads the temperature using a weather station artifact and broadcasts the reading
*/
@read_temperature_plan
+!read_temperature : true <-
	.print("I will read the temperature");
	makeArtifact("weatherStation", "tools.WeatherStation", [], WeatherStationId); // creates a weather station artifact
	focus(WeatherStationId); // focuses on the weather station artifact
	readCurrentTemperature(47.42, 9.37, Celcius); // reads the current temperature using the artifact
	.print("Temperature Reading (Celcius): ", Celcius);
	.broadcast(tell, temperature(Celcius)). // broadcasts the temperature reading

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }