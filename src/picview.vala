using Model;
using Gdk;
using Cairo;
using Math;

/* klattimer's TODO list
 *
 * FIXMEs and BUGs 
 *    - fix weird hover_behave bug
 *    - Recalculation of step increment on remove images as well as adding them
 *    - Fix z-ordering problems properly!
 *	  - Add motion buffer and kinetic calculation, this needs a lot of friction unlike a list view
 *
 * Depth cue raising selected 
 *    - z depth of selected image less than that of the stack
 *    - Compute projective transform of cursor position to cursor position at depth
 *    - The higher the instantaneous velocity the closer the selected image space is to the stack 
 *
 * Cosmetics
 *   - Cell renderer type thing which can be used to render metadata on a selected item
 *   - Scrollbar
 *   - Introduce a focus light overlay, essentially an image rendered over the stage which fades 
 *     to dark at the corners.
 *
 * API cleanups
 *   - Look at doing the event handling differently to make album.mouse_up_cb private
 *   - Try a neater solution for album.motion, try and make that private
 *   - Add a leave event callback that works, probably require calculating bounding box ourselves.
 *   - Tie up the signal emissions properly
 */


namespace Dctk {
	// TODO this is a duplication of the ScrollKineticMotion class, we should probably put this class
	// somewhere where it can be used by both.
	private class AlbumViewMotion {
		public AlbumViewMotion(float x, float y) {
			this.x = x;
			this.y = y;
			this.time.get_current_time();
		}

		public float x;
		public float y;
		public GLib.TimeVal time;
	}


	public class PictureView : Clutter.CairoTexture {
		private Clutter.Timeline timeline;
		private Clutter.Alpha alpha;
		private Clutter.BehaviourScale hover_behave;
		private AlbumView album;
		private bool mouse_down = false;
		
		private bool _has_picture;
		public bool has_picture {
			get { return _has_picture; }
		}
		private File _file;
		public File file {
			get { return _file; }
			set {
				load_image (value);
				_file = value;
			}
		}

		public signal void picture_loading (PictureView picture);
		public signal void picture_loaded (PictureView picture);
		public signal void picture_changed (PictureView picture);
		public signal void picture_removed (PictureView picture);

		public PictureView (File file, AlbumView album) {
			_has_picture = false;
			this.file = file;
			this.album = album;
			timeline = new Clutter.Timeline(300);
			
			alpha = new Clutter.Alpha.full (timeline, 	
			                                Clutter.AnimationMode.EASE_OUT_BACK);
			hover_behave = new Clutter.BehaviourScale  (alpha, 1.0, 1.0, 1.5, 1.5);
			hover_behave.apply (this);

			this.album.adjustment_changed += adjustment_changed_cb;
			this.album.size_changed += size_changed_cb;
			//button_press_event += button_press_cb;
			//button_release_event += button_release_cb;
			//leave_event += leave_cb;

			set_property("anchor-gravity", Clutter.Gravity.CENTER);
		}

		private void load_image (File file) {
			file.read_async (Priority.LOW,
			                 null,
			                 image_loaded_cb);
			picture_loading (this);
		}

		[Callback]
		private void image_loaded_cb (GLib.Object data, AsyncResult result) {
			File file = (File)data;
			float reflection_height = album.height/8.0f;
			float normal_size; 
			float new_width, new_height;
			FileInputStream  stream;
			Gdk.Pixbuf pixbuf;
			Cairo.Context cr, reflectioncr;
			Cairo.Matrix matrix; // Reflection matrix
			Cairo.ImageSurface reflection;
			Cairo.Pattern ptn; // Reflection fade pattern
			
			if (result == null) {
				debug ("Result is null!!!");
				/* TODO: throw */
				return;
			}

			try {
				//stream = file.read_finish (result);
				stream = file.read (null);
				pixbuf = new Gdk.Pixbuf.from_stream (stream, null);
			} catch {
				return;
			}
			
			normal_size = (float)(album.width/3.0);
			if (normal_size > (float)(this.album.height/2.0))
				normal_size = (float)(this.album.height/2.0);
			
			if (pixbuf.height > pixbuf.width) {
				new_height = normal_size; // FIXME this will break images taller than wide
				new_width = (int)(pixbuf.width / ((float)pixbuf.height/normal_size));
			} else {
				new_width = normal_size;
				new_height = (int)(pixbuf.height / ((float)pixbuf.width/normal_size));
			}
			
			pixbuf = pixbuf.scale_simple ((int)Math.roundf(new_width), (int)Math.roundf(new_height), Gdk.InterpType.BILINEAR);

			this.width = pixbuf.width;
			this.height = (int)(pixbuf.height + reflection_height);
			
			set_surface_size((uint)width, (uint)height);
			cr = this.create();
			
			Gdk.cairo_set_source_pixbuf(cr, pixbuf, 0, 0);
			cr.rectangle(0,2, pixbuf.width, pixbuf.height); // The 2 is here to allow the bilinear filter to
			cr.fill();                                          // antialias the image edge cheaply
			
			// Create the reflection
			reflection = new Cairo.ImageSurface(Cairo.Format.ARGB32, pixbuf.width, pixbuf.height);
			reflectioncr = new Cairo.Context(reflection);
			Gdk.cairo_set_source_pixbuf(reflectioncr, pixbuf, 0, 0);
			reflectioncr.paint();
			// This is for creating the reflection gradient, as masking tends to blend in the images behind
			// we use a gradient overlay in black instead as this is more realistic
			ptn = new Cairo.Pattern.linear(0, pixbuf.height, 0, pixbuf.height - reflection_height);
			ptn.add_color_stop_rgba(0,0,0,0,0.8);
			ptn.add_color_stop_rgba(1,0,0,0,1);
			// The inversion matrix, do not mess with it!!
			matrix = Cairo.Matrix(1.0, 0.0, 0.0, -1.0, 0, pixbuf.height*2);
			cr.set_matrix(matrix);
			// Paint the reflection
			cr.set_source_surface(reflection,0,0);
			cr.rectangle(0, 0, pixbuf.width, pixbuf.height);
			cr.fill();
			// Paint dimming over the top
			cr.set_source(ptn);
			cr.rectangle(0, 0, pixbuf.width, pixbuf.height);
			cr.fill();
			
			this.y = (this.album.height/2) - (pixbuf.height/2) + (reflection_height*2);
			this.reactive = true;
			
			if (has_picture) {
				picture_changed (this);
			} else {
				_has_picture = true;
				picture_loaded(this);
			}
		}

		[Callback]
		private void adjustment_changed_cb() {
			// NOTE: Everything is linearly calculated between each step, this is to make sure that the consistency
			// of the animation is uniform. The calculation for -1 > ? < 1 steps where an image is in presentation
			// the transform may be adjusted to provide a "cuter" appearance.
			float tx = 0, a;
			float adjust = album.adjust;

			float current_adj = (float) adjust;
			float picture_adj = (float) album.get_adjust_for_picture_view(this);

			// Calculate our current distance from centre as an adjustment value. 
			float dist = picture_adj - current_adj; // Negative to the left, positive to the right.
			
			// Calculate our distance from center as a multiple of steps
			float steps = (float)(dist / album.step_increment);

			if (steps > 0) {
				if (steps < 1) {
					// less than one step away, positiona at the relevant proportion of one step
					tx = steps * ((width/2) + (album.spacing_factor_for_selected*album.spacing));
					a = (float)(0.0 - (steps * album.angle));
					if (a > 0) {
						a = a * -1;
					}
					if (album.change > 0) {
						raise_top();
					} else {
						lower(album.selected);
					}
				} else {
					// larger than one step away
					a = 0 - album.angle;
					// The spacing of one entire step, and a multiple of spaces
					tx = ((steps - 1) * album.spacing) + ((width/2) + (album.spacing_factor_for_selected*album.spacing));
				}
			} else if (steps < 0) {
				if (steps > -1) {
					tx = steps * ((width/2) + (album.spacing_factor_for_selected*album.spacing));
					a = (float)(steps * album.angle);
					if (a < 0) {
						a = a * -1;
					}
					if (album.change < 0) {
						raise_top();
					} else {
						lower(album.selected);
					}
				} else {
					a = album.angle;
					tx = ((steps + 1) * album.spacing) - ((width/2) + (album.spacing_factor_for_selected*album.spacing));
				}
			} else {
				raise_top();
				tx = 0;
				a = 0;
			}
			this.x = tx + (album.width/2);
			set_rotation (Clutter.RotateAxis.Y_AXIS, a, 0, 0, 0);
		}
		
		[Callback]
		private void size_changed_cb() {
			// Update image size
			load_image(this.file); // Should trigger all relevant callbacks and re-sizing calculation
		}
	}

	public class AlbumView : Clutter.Group {
		private GLib.List<PictureView> pictures = new GLib.List<PictureView> ();
		private int old_height;
		private int old_width;
		private int press_x;
		private int press_y;
		private int last_x;
		private bool mouse_down = false;
		public bool motion { get; private set; }
		private float picture_width;
		public float step_increment { get; private set; }
		public float spacing = 40;
		public float angle = 75;
		public float spacing_factor_for_selected { get; private set; }
		public int change { get; private set; } // IMPROVE: this is just a hack until we know velocity and stuff like that

		private float _adjust;
		public float adjust {
			get {
				return _adjust;
			}
			set {
				if (value < 0) {
					value = 0;
				}
				if (value > 1) {
					value = 1;
				}
				var c = value - _adjust;
				if (c < 0) {
					change = -1;
				} else if (c > 0) {
					change = 1;
				} else {
					change = 0;
				}
				_adjust = value;
				_selected = get_picture_view_from_adjust(value);
				_selected.raise_top();
				picture_width = _selected.width;
				selection_changed ();
				adjustment_changed();
			}
		}

		private PictureView _selected;
		public PictureView selected {
			get {
				return _selected;
			}
			set {
				select_image(value);
			}
		}
		
		private Model.List _model;
		public Model.List model {
			get {
				return _model;
			}
			set {
				/*TODO: Model sanity check */
				_model = value;
				
				old_height = (int)this.height;
				old_width = (int)this.width;
				populate_view();
				_model.inserted += picture_inserted_cb;
				_model.removed += picture_removed_cb;
				model_changed (value);
			}
		}

		public signal void adjustment_changed ();
		public signal void selection_changed ();
		public signal void size_changed();
		public signal void model_changed (Model.List model);
		
		public signal void picture_loading (PictureView picture);
		public signal void picture_loaded (PictureView picture);
		public signal void picture_changed (PictureView picture);
		public signal void picture_removed (PictureView picture);

		public AlbumView (Model.List model) {
			adjust = 0;
			step_increment = (float)0.1;
			change = 0;
			spacing_factor_for_selected = 1.75f;
			this.reactive = true;
			motion = false;
			key_press_event += key_press_cb;
			key_release_event += key_release_cb;
			picture_width = 10;
			// Critical to the motion event being useful is the conversion of an item depth, alternatively we
			// have a single fixed depth and that is the standard depth of 0.
			button_press_event += button_press_cb;
			button_release_event += mouse_up_cb;
			//leave_event += mouse_up_cb;
			motion_event += motion_cb;
			notify["width"].connect(size_changed_cb);
			notify["height"].connect(size_changed_cb);
			this.model = model;
			show_all();
		}

		private void populate_view () {
			for (int i = 0; i < model.n_children();i++)
			{
				append_from_index (i);
			}
			return;
		}

		public float get_adjust_for_picture_view(PictureView picture) {
			int i = pictures.index(picture);
			return (float)(i * step_increment);	
		}
		
		private PictureView get_picture_view_from_adjust(float adjust) {
			int index = (int)Math.roundf(adjust/step_increment);
			return pictures.nth_data(index);
		}
		
		private float get_adjust_for_x(int x) {
			float cx = (float)x - (this.width/2);
			float adj = 0;
			
			if ((cx > -1 * ((picture_width/2) + (spacing_factor_for_selected * spacing))) && 
			    (cx < ((picture_width/2) + (spacing_factor_for_selected * spacing)))) {
				adj = (cx/((picture_width/2) + (spacing_factor_for_selected * spacing))) * step_increment;
				adj = adjust + adj;
			} else if (cx > 0) {
				adj = ((cx - ((picture_width/2) + (spacing_factor_for_selected * spacing))) / spacing) * step_increment;
				adj = adj / 2;
				adj = adjust + adj + step_increment;
			} else if (cx < 0) {
				adj = ((cx + ((picture_width/2) + (spacing_factor_for_selected * spacing))) / spacing) * step_increment;
				adj = adj / 2;
				adj = adjust + adj - step_increment;			
			}
			return adj;
		}
		
		private void select_image(PictureView picture) {
			// TODO Fire off animation from current adjustment position to the final adjustment position
			// easing can be used here
			var dest = get_adjust_for_picture_view(picture);
			//debug("Source, %f, Destination %f", adjust, dest);
			this.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 800, "adjust", dest, null );
		}
		
		private void append_from_index (int i) {
			var file_uri = (model.get_value(i) as Model.Dictionary).get_value ("picture") as SimpleString;
			var file = File.new_for_uri (file_uri.get());
			
			var picv = new PictureView (file, this);
			picv.picture_loaded += picture_loaded_cb;
		}

		public void next () {
			int next = (int)pictures.index(selected) + 1;			
			if (next > pictures.length() - 1) next = (int)pictures.length() - 1;
			var next_adj = next * step_increment;
			this.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 200, "adjust", next_adj, null );
		}

		public void previous () {
			int prev = (int)pictures.index(selected) - 1;
			if (prev < 0) prev = 0;
			var prev_adj = prev * step_increment;
			this.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 200, "adjust", prev_adj, null );
		}

		[Callback]
		public void picture_loaded_cb (PictureView picture) {
			add_actor (picture);
			picture.lower_bottom();
			
			// We maintain our order here as the group is likely to change depending on the current layer positions
			pictures.append(picture);
			//picture.button_release_event += mouse_up_cb; // Make sure we don't capture the mouse with dumb events :/
				
			float newstep;
			if (pictures.length() > 1) {
				newstep = (float)(1.0/(pictures.length()-1));
			} else {
				newstep = 1;
			}
			float newval = (float)((adjust / step_increment) * newstep);
			step_increment = newstep;
			adjust = newval; // this should trigger a change event and then each of the items updates it's position

			show_all ();
			return;
		}
		
		[Callback]
		private void picture_inserted_cb (Model.List list, int index) {
			append_from_index (index);
		}
		
		[Callback]
		private void picture_removed_cb (Model.List list, int index) {
			/* TODO
			Hide the picture, remove from the stage, then from the group (this), 
			
			// Recalculate step_increment and set adjust to the same item 
			float newstep;
			if (pictures.length() > 1) {
				newstep = (float)(1.0/(pictures.length()-1));
			} else {
				newstep = 1;
			}
			float newval = (float)((adjust / step_increment) * newstep);
			step_increment = newstep;
			adjust = newval;
			*/
			return;
		}
		
		[Callback]
		private void size_changed_cb () {
			// Recalculate the sizes of the images and spacing and spacing_factor_for_selected
			spacing = this.height / 12;
			if ((old_height != height) || (old_width != width)) {
				size_changed();
				old_height = (int)height;
				old_width = (int)width;
			}
		}

		[Callback]
		private bool key_press_cb(Clutter.Event event) {
			// TODO make a note of the time the press occurred and the button that was pressed	
			return false;
		}
		
		[Callback]
		private bool key_release_cb(Clutter.Event event) {
			// TODO act on a button press, next/previous for arrow keys
			if (event.key.hardware_keycode == 113) {
				previous();
				return true;
			}
			if (event.key.hardware_keycode == 114) {
				next();
				return true;
			}
			return false;
		}

		[Callback]
		private bool button_press_cb (Clutter.Event event) {
			press_x = (int)event.button.x;
			last_x = (int)event.button.x;
			press_y = (int)event.button.y;
			mouse_down = true;
			motion = false;
			return true;
		}
		
		[Callback]
		public bool mouse_up_cb (Clutter.Event event) {
			mouse_down = false;
			if (motion) {
				motion = false;
				selected = _selected;
				return true;
			} else {
				float adj = get_adjust_for_x((int)event.button.x);
				debug("Clicked event!! %f", adj);
				int w = (int)Math.floor(adj / step_increment);
				float d = (w * step_increment) + (step_increment/2);
				if (adj > d) {
					adj = (w + 1) * step_increment;
				} else {
					adj = w * step_increment;
				}
				debug("Adjustment snapped %f, step %f", adj, step_increment);
				this.animate(Clutter.AnimationMode.EASE_OUT_QUAD, 800, "adjust", adj, null );
				return true;
			}
			return false;
		}

		[Callback]		
		private bool motion_cb (Clutter.Event event) {
			float p_adj, m_adj;
			// TODO Is it possible to validate mouse down from event?
			if (mouse_down) {
				p_adj = get_adjust_for_x(last_x);
				m_adj = get_adjust_for_x((int)event.motion.x);
				
				adjust = adjust + (p_adj - m_adj);
				last_x = (int)event.motion.x;
				var m = press_x - event.motion.x;
				if ((m > 5) || (m < -5)) {
					motion = true;
				}
				return true;
			}
			return false;
		}
	}
}
