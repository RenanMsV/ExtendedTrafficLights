#ExtendedTrafficLights


var ExtendedTrafficLights = {

  new : func {
  	obj = { parents : [ExtendedTrafficLights], count:0};
  	return obj;
  },

  print: func (text){
  	print('Extended Traffic Lights::> ' ~ text);
  },

  initClock : func(){
  	me.refresh_timer = maketimer(.01, refreshCoord);
   	me.refresh_timer.start();
  },


  getOnlineList : func(){
  	var list= props.globals.getNode("/ai/models").getChildren("multiplayer");
  	print(size(list));
  	foreach(var a; list){
  		if (a.getNode("id").getValue() == "-1") { continue; }
  		var callsign=a.getNode("callsign").getValue();
  		print (callsign);
  	}
  },

  loadNewModel : func(modelPath, type){
  	var n = props.globals.getNode("models", 1);
  	var i = 0;
  	for (i = 0; 1==1; i += 1) {
  	  if (n.getChild("model", i, 0) == nil) {
  	    break;
  	  }
  	}
  	var objModel = n.getChild("model", i, 1);

  	objModel.getNode("elevation",1).setDoubleValue(0);
  	objModel.getNode("latitude",1).setDoubleValue(0);
  	objModel.getNode("longitude",1).setDoubleValue(0);
  	objModel.getNode("elevation-ft-prop",1).setValue(objModel.getPath()~"/elevation");
  	objModel.getNode("latitude-deg-prop",1).setValue(objModel.getPath()~"/latitude");
  	objModel.getNode("longitude-deg-prop",1).setValue(objModel.getPath()~"/longitude");
  	objModel.getNode("heading",1).setDoubleValue(0);
  	objModel.getNode("pitch",1).setDoubleValue(0);
  	objModel.getNode("roll",1).setDoubleValue(0);
  	objModel.getNode("heading-deg-prop",1).setValue(objModel.getPath()~"/heading");
  	objModel.getNode("pitch-deg-prop",1).setValue(objModel.getPath()~"/pitch");
  	objModel.getNode("roll-deg-prop",1).setValue(objModel.getPath()~"/roll");

  	objModel.getNode("path",1).setValue((getprop("/sim/fg-root") ~ "/Nasal/br_fgpassengers/models/operations.xml")); # this is the model to be loaded.

  	var loadNode = objModel.getNode("load", 1);
  	loadNode.setBoolValue(1);
  	loadNode.remove();
  	return objModel;
  },

  setPosition : func(model){
  	var coord = props.globals.getNode("position");
   	var result = getGPS(0,0,0);
   	#objModel.getNode("latitude",1).setDoubleValue(coord.getNode("latitude-deg").getValue());
   	#objModel.getNode("longitude",1).setDoubleValue(coord.getNode("longitude-deg").getValue());
   	#objModel.getNode("elevation",1).setDoubleValue(coord.getNode("altitude-ft").getValue());
  	objModel.getNode("latitude",1).setDoubleValue(result.lat());
   	objModel.getNode("longitude",1).setDoubleValue(result.lon());
   	objModel.getNode("elevation",1).setDoubleValue((coord.getNode("ground-elev-ft").getValue() != nil ? coord.getNode("ground-elev-ft").getValue() : 0));
  },

  getGPS : func(x, y, z){
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
  },
};

PlaneNode = {
	new : func (){
		me.pos = {x:0, y:0, z:0};

	}
}