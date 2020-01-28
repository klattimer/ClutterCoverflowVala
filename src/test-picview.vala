using Model;

namespace DctkTest {
	class PictureNode : Model.Dictionary {
		private Model.SimpleString picture;
		
		public override Model.Reference get_reference (string key) {
			return new Model.SimpleReference (picture);
		}
		
		public override Model.Object get_value (string key) {
			return picture;
		}
		
		public override string[] get_keys () {
			return new string[] {"picture"};
		}
		
		public PictureNode (string uri) {
			picture = new Model.SimpleString (uri);
		}
	}

	class PictureDir : Model.List {
		private GLib.List<Model.Reference> objects;
		
		public override Model.Reference get_reference (int index) {
			return objects.nth_data(index);
		}
		
		public override Model.Object get_value (int index) {
			return get_reference(index).get_value();
		}
		
		public override Model.Iterator iterator () {
			assert_not_reached ();
		}
		
		public override int n_children () {
			return (int) objects.length ();
		}
		
		public void append (Model.Object object) {
			objects.append (new SimpleReference(object));
		}
		
		public PictureDir () {
			objects = new GLib.List<Model.Reference> ();
		}
	}
	
	Dctk.AlbumView v;
	Clutter.Stage stage;
	
	public static void size_changed_cb(GLib.ParamSpec spec) {
		v.width = stage.get_width();
		v.height = stage.get_height();
		
		stdout.printf("Size changed test\n");
	}
	
	public static int main (string[] args)
	{
		//Keep test pictures in /tmp
		string[] uris = {"file:///tmp/picture1.png", 
		                 "file:///tmp/picture2.png",
		                 "file:///tmp/picture3.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png",
		                 "file:///tmp/picture4.png"};

		var picdir = new PictureDir ();
		foreach (string uri in uris) {
			picdir.append (new PictureNode (uri) as Model.Object);
		}
		
		Clutter.init (ref args);
		stage = (Clutter.Stage) Clutter.Stage.get_default ();
		stage.set_user_resizable(true);
		stage.width = 1024;
		stage.height = 600;
		v = new Dctk.AlbumView(picdir);
		v.width = stage.get_width();
		v.height = stage.get_height();
		v.x = 0;
		v.y = 0;
		stage.set_key_focus(v);
		stage.add_actor (v);
		Clutter.Color color = {0,0,0};
		stage.set_color(color);
		Clutter.Fog fog = {0.87f,1.05f};
		stage.use_fog = true;
		stage.set_fog(fog);
		stage.notify["width"] += size_changed_cb;
		stage.notify["height"] += size_changed_cb;
		stage.show_all();

		Clutter.main();
		return 0;
	}
}
