#ExtendedTrafficLights

# nome dos pilotos online

ENABLE_ADDON = "/sim/addons/extended-traffic-lights/defaultON";
MP_PLAYERS = [];
LIGHT_MODEL_PATH = "/Models/AircraftLights/LandingWhite/light_transparent.xml";
REFRESH_TIMER = {};
ENABLE_LISTENER = {};
GUINodes = {};

new = func {
	obj = { parents : [ExtendedTrafficLights], count:0};
	printETL("ExtendedTrafficLights script loaded");
	return obj;
};

var load_gui = func {
	loagdialogs();
	var data = {
		label   : "Extended Traffic Lights",
		name    : "extended_traffic_lights",
		binding : { command : "dialog-show", "dialog-name" : "extended_traffic_lights_dialog" }
	};
	GUINodes.menubar = props.globals.getNode("/sim/menubar/default/menu[7]").addChild("item");
	GUINodes.menubar.setValues(data);
	fgcommand("gui-redraw");
	printETL("ExtendedTrafficLights GUI loaded");
}

var loagdialogs = func {
	var dialogs   = ["extended_traffic_lights_dialog"];
	var filenames = ["extrlight-dialog"];
	forindex (var i; dialogs)
		GUINodes.dialog = gui.Dialog.new("/sim/gui/dialogs/" ~ dialogs[i] ~ "/dialog", getprop("sim/addons/extended-traffic-lights/path") ~ "/Dialogs/" ~ filenames[i] ~ ".xml");
}

printETL = func (text){
	print('Extended Traffic Lights::> ' ~ text);
};

initClock = func(){
	REFRESH_TIMER = maketimer(.01, func(){ getOnlineList(); refreshModelCoords();});
	REFRESH_TIMER.start();
};


getOnlineList = func(){
	# checking new players
	var list = props.globals.getNode("/ai/models").getChildren("multiplayer");
	foreach(var a; list){
	  	if (a.getNode("id").getValue() == -1) continue;
	  	var temp_model = loadNewModel(a);
	  	if (temp_model == nil) continue;
	  	var mp_player_hash = { "player" : a, "model" : temp_model};
	  	append(MP_PLAYERS, mp_player_hash); # storing mp player data, MP_PLAYERS.player stores player node,  MP_PLAYERS.model stores player's light model
	    printETL("Added: " ~ a.getNode("callsign").getValue() ~ ". Models count: " ~ size(MP_PLAYERS));
	}
	# checking if player disconnected
	foreach(var a; MP_PLAYERS){
		if(a.player.getNode("id").getValue() == -1){
			# player disconnected
		   	deleteModel(a);
		    continue;
		}
	}
};

loadNewModel = func(player){
  	# checking if model exists
  	var exists = 0;
  	foreach(var a; MP_PLAYERS){
  		if(a.player.getNode("callsign").getValue() == player.getNode("callsign").getValue()) exists = 1;
  	}
  	if (exists == 1) return nil;
  	var lat = player.getNode("/position/latitude-deg").getValue();
  	var lon = player.getNode("/position/longitude-deg").getValue();
  	var alt = player.getNode("/position/altitude-ft").getValue() * FT2M;
  	return place_model(size(MP_PLAYERS), LIGHT_MODEL_PATH, lat, lon, alt);
};

deleteModel = func (player){
	printETL("Deleted: " ~ player.player.getNode("callsign").getValue() ~ ". Models count: " ~ (size(MP_PLAYERS) - 1));
	player.model.etlmodel.remove();
	player.model.model.remove();
	MP_PLAYERS = vectorDel(player, MP_PLAYERS); # delete player entry from vector
}

refreshModelCoords = func(){
	foreach(var a; MP_PLAYERS){
		a.model.etlmodel.getNode("latitude-deg").setDoubleValue(a.player.getNode("position/latitude-deg").getValue());
		a.model.etlmodel.getNode("longitude-deg").setDoubleValue(a.player.getNode("position/longitude-deg").getValue());
		a.model.etlmodel.getNode("elevation-ft").setDoubleValue(a.player.getNode("position/altitude-ft").getValue());
  }
};

#################### inject models into the scene (helper)  * script from Sikorsky S-64 Skycrane helicopter ####################
var place_model = func(position, path, lat, lon, alt, heading = 0, pitch = 0, roll = 0) {
	var m = props.globals.getNode("models", 1);
	for (var i = 0; 1; i += 1)
		if (m.getChild("model", i, 0) == nil)
			break;
	var model = m.getChild("model", i, 1);

	setprop("/models/etf/etf["~position~"]/latitude-deg", lat);
	setprop("/models/etf/etf["~position~"]/longitude-deg", lon);
	setprop("/models/etf/etf["~position~"]/elevation-ft", alt);
	setprop("/models/etf/etf["~position~"]/heading-deg", heading);
	setprop("/models/etf/etf["~position~"]/pitch-deg", pitch);
	setprop("/models/etf/etf["~position~"]/roll-deg", roll);

	var etlmodel = props.globals.getNode("/models/etf/etf["~position~"]", 1);
	var latN = etlmodel.getNode("latitude-deg",1);
	var lonN = etlmodel.getNode("longitude-deg",1);
	var altN = etlmodel.getNode("elevation-ft",1);
	var headN = etlmodel.getNode("heading-deg",1);
	var pitchN = etlmodel.getNode("pitch-deg",1);
	var rollN = etlmodel.getNode("roll-deg",1);

	model.getNode("path", 1).setValue(path);
	model.getNode("latitude-deg-prop", 1).setValue(latN.getPath());
	model.getNode("longitude-deg-prop", 1).setValue(lonN.getPath());
	model.getNode("elevation-ft-prop", 1).setValue(altN.getPath());
	model.getNode("heading-deg-prop", 1).setValue(headN.getPath());
	model.getNode("pitch-deg-prop", 1).setValue(pitchN.getPath());
	model.getNode("roll-deg-prop", 1).setValue(rollN.getPath());
	model.getNode("load", 1).remove();

	return { "model" : model, "etlmodel" : etlmodel };
};

getGPS = func(x, y, z){
    # get Coord from body structural position. x,y,z must be in meters.
    # Derived from Vivian Meazza's code in AIModel/submodel.cxx by Alexis Bory.
    # Bugfixes by Nikolai V. Chr.

    var ac = geo.aircraft_position();

    if(x == 0 and y==0 and z==0) {
     		return geo.Coord.new(ac);
    }

    var ac_roll = getprop("orientation/roll-deg");
    var ac_pitch = getprop("orientation/pitch-deg");
    var ac_hdg   = getprop("orientation/heading-deg");

    var in    = [0,0,0];
    var trans = [[0,0,0],[0,0,0],[0,0,0]];
    var out   = [0,0,0];

    in[0] =  -x * M2FT;
    in[1] =   y * M2FT;
    in[2] =   z * M2FT;
    # Pre-process trig functions:
    var cosRx = math.cos(-ac_roll * D2R);
    var sinRx = math.sin(-ac_roll * D2R);
    var cosRy = math.cos(-ac_pitch * D2R);
    var sinRy = math.sin(-ac_pitch * D2R);
    var cosRz = math.cos(ac_hdg * D2R);
    var sinRz = math.sin(ac_hdg * D2R);
    # Set up the transform matrix:
    trans[0][0] =  cosRy * cosRz;
    trans[0][1] =  -1 * cosRx * sinRz + sinRx * sinRy * cosRz ;
    trans[0][2] =  sinRx * sinRz + cosRx * sinRy * cosRz;
    trans[1][0] =  cosRy * sinRz;
    trans[1][1] =  cosRx * cosRz + sinRx * sinRy * sinRz;
    trans[1][2] =  -1 * sinRx * cosRx + cosRx * sinRy * sinRz;
    trans[2][0] =  -1 * sinRy;
    trans[2][1] =  sinRx * cosRy;
    trans[2][2] =  cosRx * cosRy;
    # Multiply the input and transform matrices:
    out[0] = in[0] * trans[0][0] + in[1] * trans[0][1] + in[2] * trans[0][2];
    out[1] = in[0] * trans[1][0] + in[1] * trans[1][1] + in[2] * trans[1][2];
    out[2] = in[0] * trans[2][0] + in[1] * trans[2][1] + in[2] * trans[2][2];
    # Convert ft to degrees of latitude:
    out[0] = out[0] / (366468.96 - 3717.12 * math.cos(ac.lat() * D2R));
    # Convert ft to degrees of longitude:
    out[1] = out[1] / (365228.16 * math.cos(ac.lat() * D2R));
    # Set position:
    var mlat = ac.lat() + out[0];
    var mlon = ac.lon() + out[1];
    var malt = (ac.alt() * M2FT) + out[2];

    var c = geo.Coord.new();
    c.set_latlon(mlat, mlon, malt * FT2M);

    return c;
};

var getAddonPath = func {
	listN = props.globals.getNode("addons").getChildren("addon");
	forindex (var n; listN) {
		splited = split('/', listN[n].getChild("path").getValue());
		if (splited[size(splited)-1] == "extended_traffic_lights") {
			props.globals.initNode("/sim/addons/extended-traffic-lights/path", listN[n].getChild("path").getValue());
			props.globals.initNode("/sim/addons/extended-traffic-lights/namespace", '__addon[' ~ n ~ ']__');
			LIGHT_MODEL_PATH = listN[n].getChild("path").getValue() ~ LIGHT_MODEL_PATH;
		}
	}
};

var vectorDel = func (entry, vector){
	var _temp_vector = [];
	foreach(var a; vector){
		if(a != entry) append(_temp_vector, a);
	}
	return _temp_vector;
};

var enable = func {
	initClock();
	printETL("ExtendedTrafficLights script enabled");
};

var disable = func {
	REFRESH_TIMER.stop();
	forindex(var n; MP_PLAYERS){
		deleteModel(MP_PLAYERS[n]);
	}
	printETL("Extended Traffic Lights script disabled");
}

var main = func ( root ) {
	var fdm_init_listener = _setlistener("/sim/signals/fdm-initialized", func {
		printETL(root);
		getAddonPath();
		load_gui();
		removelistener(fdm_init_listener);
		if(getprop('/sim/addons/extended-traffic-lights/defaultON')) {
			setprop('/sim/addons/extended-traffic-lights/enable', 1);
			props.globals.getNode('/sim/addons/extended-traffic-lights/enable').setDoubleValue(1);
		}
		ENABLE_LISTENER = setlistener("/sim/addons/extended-traffic-lights/enable", func (val) {
		    if (val.getValue()) enable(); else disable();
		}, 1, 0);
	});
	var reinit_listener = _setlistener("/sim/signals/reinit/", func {
		removelistener(ENABLE_LISTENER);
		disable();
		GUINodes.menubar.remove();
		GUINodes.dialog.del();
	});
};
# carregar lista de jogadores online
# recuperar posicao de um por um
# instanciar um objeto de luz na posição correta
# continuar atualizando posicoes e checando se existem novos jogadores.