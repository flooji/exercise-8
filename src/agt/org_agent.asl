// organization agent

/* Initial beliefs and rules */
org_name("lab_monitoring_org"). // the agent beliefs that it can manage organizations with the id "lab_monitoting_org"
group_name("monitoring_team"). // the agent beliefs that it can manage groups with the id "monitoring_team"
sch_name("monitoring_scheme"). // the agent beliefs that it can manage schemes with the id "monitoring_scheme"

roles([]).

has_enough_players_for(R) :- role_cardinality(R,Min,Max) & .count(play(_,R,_),NP) & NP >= Min.

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: greets the user
*/
@start_plan
+!start : org_name(OrgName) & group_name(GroupName) & sch_name(SchemeName) <-
  .print("I will initialize an organization ", OrgName, " with a group ", GroupName, " and a scheme ", SchemeName, " in workspace ", OrgName);
  !create_org(GroupName, OrgName, SchemeName).

/* 
 * Plan for reacting to the addition of the goal !create_org
 * Triggering event: addition of goal !create_org
 * Context: always true
 * Body: the agent creates an organization, group and scheme and manages the formation of the group
*/
+!create_org(GroupName, OrgName, SchemeName) <- 
  createWorkspace(OrgName)
  joinWorkspace(OrgName, WspId)
  .print("Joined workspace ", OrgName)
  makeArtifact(OrgName, "ora4mas.nopl.OrgBoard", ["src/org/org-spec.xml"], OrgArtId)[wid(WspId)]
  focus(OrgArtId)[wid(WspId)]
  createGroup(GroupName, GroupName, GrArtId)[artifact_id(OrgArtId)]
  focus(GrArtId)[wid(WspId)]
  .print("Created organization ", OrgName, " with group ", GroupName)
  .broadcast(tell, new_gr(OrgName, GroupName))
  //!inspect(GrArtId)
  !manage_formation(GroupName, OrgName)
  !afterFormation.

/* 
 * Plan for reacting to the addition of the goal manage_formation
 * Triggering event: addition of goal !manage_formation(GroupName, OrgName)
 * Context: the agent holds the belief of two roles
 * Body: while the group formation status is not well formed, the agent will every 15s broadcast available roles.
 * the agent waits until the belief is added in the belief base
*/
@manage_group_formation_plan
+!manage_formation(GroupName, OrgName): roles([R1, R2]) <- 
while(formationStatus(nok)[artifact_id(GroupId)]) {
    .wait(15000)
    .print("Manage formation for group: ", GroupName)
    if(not has_enough_players_for(R1)) {
      .broadcast(tell, role_available(R1, GroupName, OrgName))
    }
    if(not has_enough_players_for(R2)) {
      .broadcast(tell, role_available(R2, GroupName, OrgName))
    }
}.

// Plan to wait until the group managed by the Group Board artifact G is well-formed
// Makes this intention suspend until the group is believed to be well-formed
+!afterFormation : group(GroupName,_,G)[artifact_id(OrgName)] & sch_name(SchemeName) <-
  ?formationStatus(ok)[artifact_id(G)]
  .print("Creating scheme ", SchemeName," because group is well-formed")
  createScheme(SchemeName, SchemeName, SchArtId)[artifact_id(OrgArtId)]
  addScheme(SchemeName)[artifact_id(GrArtId)]
  focus(SchArtId)[wid(WspId)].

/* 
 * Plan for reacting to the addition of the test-goal ?formationStatus(ok)
 * Triggering event: addition of goal ?formationStatus(ok)
 * Context: the agent beliefs that there exists a group G whose formation status is being tested
 * Body: if the belief formationStatus(ok)[artifact_id(G)] is not already in the agents belief base
 * the agent waits until the belief is added in the belief base
*/
@test_formation_status_is_ok_plan
+?formationStatus(ok)[artifact_id(G)] : group(GroupName,_,G)[artifact_id(OrgName)] <-
  .print("Waiting for group ", GroupName," to become well-formed");
  .wait({+formationStatus(ok)[artifact_id(G)]}). // waits until the belief is added in the belief base

/* 
 * Plan for reacting to the addition of the goal !inspect(OrganizationalArtifactId)
 * Triggering event: addition of goal !inspect(OrganizationalArtifactId)
 * Context: true (the plan is always applicable)
 * Body: performs an action that launches a console for observing the organizational artifact 
 * identified by OrganizationalArtifactId
*/
@inspect_org_artifacts_plan
+!inspect(OrganizationalArtifactId) : true <-
  // performs an action that launches a console for observing the organizational artifact
  // the action is offered as an operation by the superclass OrgArt (https://moise.sourceforge.net/doc/api/ora4mas/nopl/OrgArt.html)
  debug(inspector_gui(on))[artifact_id(OrganizationalArtifactId)]. 

/* 
 * Plan for reacting to the addition of the belief play(Ag, Role, GroupId)
 * Triggering event: addition of belief play(Ag, Role, GroupId)
 * Context: true (the plan is always applicable)
 * Body: the agent announces that it observed that agent Ag adopted role Role in the group GroupId.
 * The belief is added when a Group Board artifact (https://moise.sourceforge.net/doc/api/ora4mas/nopl/GroupBoard.html)
 * emmits an observable event play(Ag, Role, GroupId)
*/
@play_plan
+play(Ag, Role, GroupId) : true <-
  .print("Agent ", Ag, " adopted the role ", Role, " in group ", GroupId).

+specification(os(_, group_specification(_, [role(R1, _, _, _, _, _, _), role(R2, _, _, _, _, _, _)], _, _) ,_, _)): true 
<- +roles([R1, R2]).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }