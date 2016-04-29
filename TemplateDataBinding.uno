using Uno;
using Uno.Collections;
using Fuse;
using Fuse.Reactive;
using Uno.UX;

namespace Fuse.Reactive
{

[UXAutoGeneric("TemplateDataBinding", "Target")]
[UXValueBindingAlias("Template")]
public class TemplateDataBinding<T>: Behavior, IPartSetter
{

		[UXConstructor]
		public TemplateDataBinding([UXParameter("Target")] Property<T> target, [UXParameter("Key")] string key)
		{
			Target = target;
			Key = key;
		}

		[UXValueBindingTarget]
		public Property<T> Target { get; private set; }

		[UXValueBindingArgument]
		public string Key { get; private set; }

		protected Node Node { get; private set; }

		protected override void OnRooted(Node n)
		{
			Node = n;
			n.DataContextChanged += OnDataContextChanged;
			ValueSetter(Key);

			if (n.DataContext != null)
				OnDataContextChanged(n, new DataContextChangedArgs(n, null, n.DataContext));
		}

		protected override void OnUnrooted(Node n)
		{
			n.DataContextChanged -= OnDataContextChanged;
			Node = null;

			if (n.DataContext != null)
				OnDataContextChanged(n, new DataContextChangedArgs(n, null, null));
		}

		void OnDataContextChanged(object sender, DataContextChangedArgs args)
		{
			ValueSetter(Key);
		}

		public void IPartSetter.SetPart(string v, int part) {
			debug_log "Setting part " + part + " to " + v + " ("+ parts[part] +")";
			parts[part] = v;
			missing -= 1;
			debug_log "missing " + missing;
			if (missing == 0) {
				UpdateManager.PostAction(SetTargetValue);
			}
		}
		void SetTargetValue()
		{
			if (Node == null) {
				return;
			}

			var n = "";
			foreach (var p in parts) {
				n += p;
			}
			Target.SetRestState((T)n, this);
		}

		List<string> parts = new List<string>();
		int missing = 0;
		void ValueSetter(object newValue)
		{
			if (Node == null) {
				return;
			}
			parts.Clear();
			missing = 0;
			debug_log "Setting parts to " + newValue;
			var s = newValue as string;
			if (s != null) {
				string n = "";
				string varname = "";
				bool inside = false;
				foreach (var c in s) {
					if (c == '{') {
						if (n != "") {
							parts.Add(n);
						}
						n = "";
						varname = "";
						inside = true;
					} else
					if (c == '}') {
						n = "";
						debug_log varname;
						parts.Add(varname);
						if (Node.DataContext != null) {
							missing += 1;
							var r = new Resolver(varname, this, parts.Count-1, Node.DataContext);
						}
						varname = "";
						inside = false;
					} else
					if (inside) {
						varname = varname + c;
					} 
					else {
						n = n + c;
					}
				}
				if (n != "") {
					parts.Add(n);
				}
				newValue = n;
			}
			if (missing == 0) {
				SetTargetValue();
			}

			// Target.SetRestState((T)newValue, this);

		}

}

	public class Resolver {
		public Resolver(string v, IPartSetter b, int i, object dc) {
			binding = b;
			index = i;
			Resolve(v, dc);
		}

		int index;
		IPartSetter binding;

		public void Resolve(string s, object dc) {
			debug_log "Resolve " + s + " in " + dc;
			var iao = dc as IAsyncObject;
			if (iao != null) {
				iao.Tell(s, Dispatcher.UIThread, HandleObjectCallback);
			}
		}

		void HandleObjectCallback(object val)
		{
			debug_log "Callback " + val;
			binding.SetPart((string)val, index);
		}
	}

	public interface IPartSetter {
		void SetPart(string v, int part);
	}

}