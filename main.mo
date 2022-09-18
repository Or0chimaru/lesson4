import Array "mo:base/Array";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

shared (install) actor class Microblog() {
  private stable var owner : Principal = install.caller;

  public type Message = {
    content: Text;
    time: Time.Time;
    id: Text;
  };
  public type Microblog = actor {
    follow: shared(Principal) -> async (); // add following
    follows: shared query () -> async [Principal]; // return following people list
    post: shared (Text) -> async (); // post microblog
    posts: shared query (since: Time.Time) -> async [Message]; // return all of posted microblog after time_point
    timeline: shared (since: Time.Time) -> async [Message]; // return all of following people posted microblog
  };

  stable var followed : List.List<Principal> = List.nil();

  public shared func follow(id: Principal) : async () {
    followed := List.push(id, followed);
  };

  public shared query func follows() : async [Principal] {
    List.toArray(followed);
  };

  stable var messages : List.List<Message> = List.nil();

  public shared (msg) func post(text: Text) : async () {
    messages := List.push({content = text; time = Time.now(); id= Principal.toText(msg.caller)}, messages);
  };

  public shared (msg) func get_principal() : async Text {
    Principal.toText(msg.caller);
  };


  public shared query func posts(since: Time.Time) : async [Message] {
    let apst = List.toArray(messages);
    let afterSince = func(x: Message) : Bool { x.time > since };
    let res = Array.filter(apst, afterSince);

    return res;
  };


  public shared func timeline(since: Time.Time) : async [Message] {
    var all : List.List<Message> = List.nil();

    for (id in Iter.fromList(followed)) {
      let canister : Microblog = actor(Principal.toText(id));
      let msgs = await canister.posts(since);
      for (msg in Iter.fromArray(msgs)) {
        all := List.push(msg, all);
      };
    };

    List.toArray(all);

  };
};