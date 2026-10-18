// Construct around the upstream WashTower's exact official envelope and record sizes.
fn status(tag,record) {
 let n=record.len();let size=n+18;
 let frame=blob();
 for b in [0xaa,0xff,tag,0x0a,0,size%256,size/256,0,0,0,1,0,0xeb,n/256,n%256] {frame.push(b);}
 frame+=record;
 let crc=crc16(frame);frame.push(crc/256);frame.push(crc%256);frame.push(0xbb);
 hex_encode(frame)
}
fn response(tag) {hex_encode(aabb_wrap([tag,0xe6,0,2,1,255,1,2,0]))}
