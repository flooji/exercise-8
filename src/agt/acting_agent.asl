// acting agent

// The agent has a belief about the location of the W3C Web of Thing (WoT) Thing Description (TD)
// that describes a Thing of type https://ci.mines-stetienne.fr/kg/ontology#PhantomX
robot_td("https://raw.githubusercontent.com/Interactions-HSG/example-tds/main/tds/leubot1.ttl").

/* Rules */ 
role_goal(R, G):-
	role_mission(R,_,M) &
	mission_goal(M,G).

has_plans_for(G) :-
	.relevant_plans({+!G},LP) & LP \== [].

i_have_plans_for(R):-
	not(role_goal(R,G) & not has_plans_for(G)).

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

/* 
 * Plan for reacting to the addition of the goal !manifest_temperature
 * Triggering event: addition of goal !manifest_temperature
 * Context: the agent believes that there is a temperature in Celcius and
 * that a WoT TD of an onto:PhantomX is located at Location
 * Body: converts the temperature from Celcius to binary degrees that are compatible with the 
 * movement of the robotic arm. Then, manifests the temperature with the robotic arm
*/
@manifest_temperature_plan 
+!manifest_temperature : temperature(Celcius) & robot_td(Location) <-
	.print("I will manifest the temperature: ", Celcius);
	makeArtifact("covnerter", "tools.Converter", [], ConverterId); // creates a converter artifact
	convert(Celcius, -20.00, 20.00, 200.00, 830.00, Degrees)[artifact_id(ConverterId)]; // converts Celcius to binary degress based on the input scale
	.print("Temperature Manifesting (moving robotic arm to): ", Degrees).

+role_available(Role, GroupName, OrgName) <-
	// Join workspace
	joinWorkspace(OrgName, WspId);
	.print("Joined workspace ", OrgName);
	
	// Focus on org & group artifacts (this is necessary to have i_have_plans_for(Role) working)
	lookupArtifact(OrgName, OrgArtId)[wid(WspId)];
	focus(OrgArtId)[wid(WspId)];
	lookupArtifact(GroupName, GrArtId)[wid(WspId)];
	focus(GrArtId);
	.print("Got notification for ", Role, " in organization ", OrgName)

	// Check if the agents has matching plans, if so it will adopt the role
	if(i_have_plans_for(Role)) {
		.print("I have plans for role ", Role);
		adoptRole(Role)[artifact_id(GrArtId)];
		.print("Joined ", GroupName, " in ", OrgName, " as ", Role);
	} else {
		.print("I don't have plans for role ", Role);
	}.

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }
