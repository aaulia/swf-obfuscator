package ;

import cpp.io.File;
import cpp.Lib;
import cpp.Sys;
import cpp.vm.Gc;
import cpp.zip.Compress;
import cpp.zip.Uncompress;
import haxe.Int32;
import haxe.io.Bytes;

/**
 * ...
 * @author Achmad Aulia Noorhakim
 */

typedef SWF = {
	var sig    :String;
	var version:Int;
	var length :Int32;
	var data   :Bytes;
}
 
class Main {
	
	static function main() {
		var args = Sys.args();
		if (args.length < 2) {
			print_help();
		}
		
		var fnSWF = args.shift();
		var fnDCT = args.shift();
		var fnOUT = (args.length > 0) ? args.shift() : generate_output_fn(fnSWF);
		
		var names = read_dictionaries(fnDCT);
		var subst = create_random_subst(names);
		var input = read_swf(fnSWF);
		
		obfuscate(input, names, subst);
		write_swf(input, fnOUT);
		
		Gc.run(true);
		Sys.exit(0);
	}
	
	static private function write_swf(swf:SWF, filename:String):Void {
		if (swf.sig == 'CWS') {
			swf.data = Compress.run(swf.data, 9);
		}
		
		var out = File.write(filename, true);
		out.writeString(swf.sig);
		out.writeInt8  (swf.version);
		out.writeInt32 (swf.length);
		out.writeBytes (swf.data, 0, swf.data.length);
		out.close();
	}
	
	static private function obfuscate(swf:SWF, n:Array<String>, s:Array<Bytes>):Void {
		for (i in 0...n.length) {
			var pos = 0;
			var chk = n[i];
			var sub = s[i];
			var len = chk.length;
			var max = swf.data.length - len;
			var got = 0;
			
			Lib.print(chk + ": ");
			
			while (pos < max) {
				if (swf.data.readString(pos, len) != chk) {
					++pos;
				} else {
					swf.data.blit(pos, sub, 0, len);
					pos += len;
					++got;
				}
			}
			
			Lib.println(got + " found");
		}
	}
	
	static private function create_random_subst(names:Array<String>):Array<Bytes> {
		var subst = new Array<Bytes>();
		for (n in names) {
			var alt = create_random_name(n.length);
			while (check_if_name_exists(subst, alt)) {
				alt = create_random_name(n.length);
			}
			subst.push(Bytes.ofString(alt));
		}
		return subst;
	}
	
	static private function check_if_name_exists(s:Array<Bytes>, a:String):Bool {
		for (i in s) {
			if (i.toString() == a) {
				return true;
			}
		}
		return false;
	}
	
	static private function create_random_name(length:Int):String {
		var chars = '@#$%&_^?';
		var name  = '';
		for (i in 0...length) {
			name += chars.charAt(cast(Math.random() * chars.length));
		}
		return name;
	}
	
	static private function read_swf(fn:String):SWF {
		var inp = File.read(fn, true);
		var swf = {
			sig    : inp.readString(3),
			version: inp.readInt8(),
			length : inp.readInt32(),
			data   : inp.readAll()
		};
		
		inp.close();
		if (swf.sig == 'CWS') {
			swf.data = Uncompress.run(swf.data);
		}
		
		return swf;
	}
	
	static private function read_dictionaries(dict:String):Array<String> {
		var inp = File.read(dict, false);
		var dct = new Array<String>();
		
		inp.seek(0, FileSeek.SeekEnd);
		if (inp.tell() > 0) {
			inp.seek(0, FileSeek.SeekBegin);
			while (!inp.eof()) {
				dct.push(inp.readLine());
			}
		}
		inp.close();
		dct.sort(function(a, b) { return b.length - a.length; });
		return dct;
	}
	
	static private function generate_output_fn(ori:String):String {
		var dot_last_index = ori.lastIndexOf('.');
		var filename_noext = ori.substr(0, dot_last_index - 1);
		return filename_noext + '-obf' + ori.substr(dot_last_index, ori.length - dot_last_index);
	}
	
	static private function print_help():Void {
		Lib.println('Usage: swf-obfuscator <swf-filename> <dictionary-filename> [output-filename]');
		Sys.exit(0);
	}
	
}