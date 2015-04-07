package stb.format.vorbis.flash;
import flash.events.Event;
import flash.events.IEventDispatcher;
import flash.events.SampleDataEvent;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundTransform;
import haxe.io.BytesOutput;
import stb.format.vorbis.VorbisDecoder;

class VorbisSoundChannel implements IEventDispatcher {
	public var channel(default, null):SoundChannel;
	
	public var leftPeak(get, never):Float;
	function get_leftPeak():Float {
		return channel.leftPeak;
	}
	
	public var position(get, never):Float;
	function get_position():Float {
		return reader.currentMillisecond;
	}
	
	public var rightPeak(get, never):Float;
	function get_rightPeak():Float {
		return channel.rightPeak;
	}
	
	public var soundTransform(get, set):SoundTransform;
	function get_soundTransform():SoundTransform {
		return channel.soundTransform;
	}
	function set_soundTransform(value:SoundTransform):SoundTransform {
		return channel.soundTransform = value;
	}
	
	public var currentLoop(default, null):Int;
	public var loop(default, null):Int;
	
	var reader(default, null):Reader;
	var loopReader(default, null):Reader;
	
	function new (reader:Reader, startSample:Int, loop:Int, loopStartSample:Int) {
		this.reader = reader;
		this.loop = loop;
		
		currentLoop = 0;
		reader.currentSample = startSample;
		
		if (loop > 1) {
			loopReader = reader.clone();
			loopReader.currentSample = loopStartSample;
		}
	}
	
	static public function play(sound:Sound, reader:Reader, startTime:Float = 0, loop:Int = 0, looptartTime:Float = 0, ?soundTransform:SoundTransform) {
		var vorbisChannel = new VorbisSoundChannel(
			reader, 
			reader.millisecondToSample(startTime), 
			loop, 
			reader.millisecondToSample(looptartTime)
		);
		
		sound.addEventListener(SampleDataEvent.SAMPLE_DATA, vorbisChannel.onSampleData);
		var channel = sound.play(startTime, loop, soundTransform);
		if (channel == null) {
			return null;
		} else {
			vorbisChannel.channel = channel;
			return vorbisChannel;
		}
	}
	
	public function stop():Void {
		channel.stop();
	}
	
	function onSampleData(event:SampleDataEvent):Void {
		var output:BytesOutput = new BytesOutput();
		untyped output.b = event.data;
		
		var n = 0;
		if (loop <= 1 || loopReader.currentSample < reader.totalSample - 1) {
			for (i in 0...8192) {
				n += reader.read(output, 8192 - n, 2, 44100, true);
				if (n < 8192) {
					if (currentLoop < loop - 1) {
						currentLoop++;
						reader = loopReader.clone();
					} else {
						break;
					}
				} else {
					break;
				}
			}
		}
	}
	
	// EventListener
	public function addEventListener(type:String, listener:Dynamic->Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void 
	{
		channel.addEventListener(type, listener, useCapture, priority, useWeakReference);
	}
	
	public function removeEventListener(type:String, listener:Dynamic->Void, useCapture:Bool = false):Void 
	{
		channel.removeEventListener(type, listener, useCapture);
	}
	
	public function dispatchEvent(event:Event):Bool 
	{
		return channel.dispatchEvent(event);
	}
	
	public function hasEventListener(type:String):Bool 
	{
		return channel.hasEventListener(type);
	}
	
	public function willTrigger(type:String):Bool 
	{
		return channel.willTrigger(type);
	}
}