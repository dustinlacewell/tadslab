#charset "us-ascii"
#include <tads.h>
#include <lookup.h>
#include "advlite.h"

symtabObj: PreinitObject
  execute()
  {
    // stash a reference to the symbol table in
    // my 'symtab' property, so that it will
    // remain available at run-time
    symtab = t3GetGlobalSymbols();
  }
  symtab = nil
;

directionMap: object
    map = new LookupTable()
    construct() {
        map['north'] = northDir;
        map['south'] = southDir;
        map['east'] = eastDir;
        map['west'] = westDir;
        map['northwest'] = northwestDir;
        map['northeast'] = northeastDir;
        map['southwest'] = southwestDir;
        map['southeast'] = southeastDir;
        map['up'] = upDir;
        map['down'] = downDir;
    }
;

reversalMap: object
    map = new LookupTable()
    construct() {
        map['north'] = southDir;
        map['south'] = northDir;
        map['east'] = westDir;
        map['west'] = eastDir;
        map['northwest'] = southeastDir;
        map['northeast'] = southwestDir;
        map['southwest'] = northeastDir;
        map['southeast'] = northwestDir;
        map['up'] = downDir;
        map['down'] = upDir;
    }           
;

modify Thing
    /* This class modification allows us to get and set the value of object
    properties at runtime if we have the name of a property in a string. */

    getProp(name) {
      local prop = symtabObj.symtab[name];
      local value = self.(prop);
      return value;
    }    

    setProp(name, value) {
      local prop = symtabObj.symtab[name];
      self.(prop) = value;
    }
;

modify Room
    /* With this class modification we add some methods for enabling any room to
    'tunnel' to another room, in one of the standard directions. The other room
    will also get an exit leading back to this one. */

    makeRoom(dir, roomInfo?) {
        /* This method creates a new room based on the provided `roomInfo`
        parameter. If `roomInfo` is an existing room, we just return it as
        is. If it is a class, we return an instance of that class. If it 
        is a string, we create a plain Room instance and set the
        description. */

        if (roomInfo.ofKind(Room)) { return roomInfo; }
        if (roomInfo.isClass()) { return roomInfo.createInstance(); }
        local newRoom = new Room();
        newRoom.desc = roomInfo;
        return newRoom;
    }

    addRoom(dir, roomInfo?) {
        /* This method takes an exit direction and a `roomInfo` parameter
        (described in the `makeRoom` method above) and creates a
        bi-directional exit relationship between it and this room. */

        // determine the opposite direction
        local revDir = reversalMap.map[dir.name];
        // provision the target rooom
        local newRoom = makeRoom(revDir, roomInfo);
        // set the exit on this room
        setProp(dir.name, newRoom);
        // set the exit on the target room
        newRoom.setProp(revDir.name, self);
        // call handler to allow for any post processing
        connectRooms(self, dir, newRoom, revDir);
    }

    connectRooms(out, outDir, in, inDir) { 
        /* This method is for allowing authors to handle the linking of rooms
        in order to provide any post-processing operations. Such an example 
        would be creating doors for each side of the connection. It does
        nothing by default. */
    }
;

DefineLiteralAction(Tunnel)
    execAction(cmd)
    {
        // get Direction object by name
        local dir = directionMap.map[gLiteral];
        // bail if provided direction doesn't exist
        if (dir == nil) { "That is not a direction you can tunnel. "; return; }
        // bail if this room already has an exit in that direction
        if (gActor.location.getProp(dir.name)) {
           "There is already a path <<dir.departureName>>. "; return;
        }
        "You dig a room <<dir.departureName>>.";
        gActor.location.addRoom(dir, getNewRoom());
    }

    getNewRoom() { 
        /* This method can be overriden in your own game to provide stronger
        logic for what kind of room should be created on the other side of
        the tunnel. You can return either a Room subclass, a Room instance or
        a string representing a new default Room description. */
        return 'The newly dug room smells of fresh earth. '; 
    }
;

VerbRule(Tunnel)
    'tunnel' literalDobj
    : VerbProduction
    action = Tunnel
    verbPhrase = 'tunnel/tunneling'
    missingQ = 'Which direction do you want to tunnel?'
;

replace VerbRule(Dig)
    'dig' literalDobj
    : VerbProduction
    action = Tunnel
    verbPhrase = 'dig/digging'
    missingQ = 'Which direction do you want to dig?'
;

versionInfo: GameID
    IFID = ''
    name = ''
    byline = 'by YOUR NAME'
    htmlByline = 'by <a href="mailto:YOUR@ADDRESS.com">
                  YOUR NAME</a>'
    version = '1'
    authorEmail = 'YOUR NAME <YOUR@ADDRESS.com>'
    desc = ''
    htmlDesc = ''
;

gameMain: GameMainDef
    initialPlayerChar = me
;

startRoom: Room 'Start'
    "You are in a dark underground cavitation. How you got here is anyone's guess. At least you have a magical shovel. "
;

+ me: Thing 'you'     
    isFixed = true       
    person = 2
    contType = Carrier
    firstName = 'Dustin'
;

++ shovel: Thing 'magical shovel'
   "The shovel is magical."
;