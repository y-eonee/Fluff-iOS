import AppKit
import SceneKit

@main struct RenderFurnitureB {
 static func color(_ hex:String)->NSColor {
  let n=UInt32(hex.dropFirst(),radix:16) ?? 0xffffff
  return NSColor(srgbRed:CGFloat((n>>16)&255)/255,green:CGFloat((n>>8)&255)/255,blue:CGFloat(n&255)/255,alpha:1)
 }
 static func entity(_ kind:FurnitureKind)->SCNNode {
  let root=SCNNode()
  for p in FurnitureModelB.parts(for:kind) {
   let g:SCNGeometry
   switch p.shape {
   case .box:g=SCNBox(width:CGFloat(p.size.x),height:CGFloat(p.size.y),length:CGFloat(p.size.z),chamferRadius:CGFloat(min(p.radius,p.size.min()/3)))
   case .sphere:g=SCNSphere(radius:0.5)
   case .cylinder:g=SCNCylinder(radius:0.5,height:1)
   case .cone:g=SCNCone(topRadius:0.23,bottomRadius:0.5,height:1)
   }
   let m=SCNMaterial();m.diffuse.contents=color(p.color);m.roughness.contents=0.88;m.metalness.contents=0;m.lightingModel = .physicallyBased
   if p.glow {m.emission.contents=color("#FFF4D8").withAlphaComponent(0.35)}
   g.materials=[m];let n=SCNNode(geometry:g);n.simdPosition=p.position
   if p.shape != .box {n.simdScale=p.size}
   root.addChildNode(n)
  }
  return root
 }
 static func snapshot(_ node:SCNNode,target:SIMD3<Float>,scale:Double,size:CGSize)->NSImage {
  let scene=SCNScene();scene.rootNode.addChildNode(node)
  let ambient=SCNNode();ambient.light=SCNLight();ambient.light!.type = .ambient;ambient.light!.intensity=650;scene.rootNode.addChildNode(ambient)
  let light=SCNNode();light.light=SCNLight();light.light!.type = .directional;light.light!.intensity=1400;light.light!.castsShadow=true;light.light!.shadowRadius=6;light.simdPosition=[1.5,3,2];light.look(at:SCNVector3Zero);scene.rootNode.addChildNode(light)
  let camera=SCNNode();camera.camera=SCNCamera();camera.camera!.usesOrthographicProjection=true;camera.camera!.orthographicScale=scale;camera.simdPosition=target+[5,4.25,5];camera.look(at:SCNVector3(target));scene.rootNode.addChildNode(camera)
  let renderer=SCNRenderer(device:nil,options:nil);renderer.scene=scene;renderer.pointOfView=camera
  return renderer.snapshot(atTime:0,with:size,antialiasingMode:.multisampling4X)
 }
 static func save(_ image:NSImage,_ path:String)throws {let b=NSBitmapImageRep(data:image.tiffRepresentation!)!;try b.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:path))}
 static func main()throws {
  let dest=CommandLine.arguments[1];try FileManager.default.createDirectory(atPath:dest,withIntermediateDirectories:true)
  let selected = Set(CommandLine.arguments.dropFirst(2))
  for k in FurnitureKind.allCases where k.isMovable && (selected.isEmpty || selected.contains(k.rawValue)) {
   let node=entity(k);let bounds=node.boundingBox;let lo=SIMD3<Float>(Float(bounds.min.x),Float(bounds.min.y),Float(bounds.min.z)),hi=SIMD3<Float>(Float(bounds.max.x),Float(bounds.max.y),Float(bounds.max.z));let size=hi-lo
   let scale = k == .rugRound ? Double(max(size.x,size.z)) * 0.38 : k == .rugSquare ? Double(max(size.x,size.z)) * 0.48 : Double(max(size.x+size.z,size.y*2))*0.6
   let image=snapshot(node,target:(lo+hi)/2,scale:scale,size:CGSize(width:480,height:360))
   try save(image,dest+"/b_furniture_"+k.rawValue+".png")
  }
  guard selected.isEmpty else { print("Rendered selected B furniture previews"); return }
  let room=SCNNode()
  for (k,x,z):(FurnitureKind,Float,Float) in [(.wall,0,0),(.floor,0,0),(.rugRound,0.2118,0.2119),(.bed,-0.5996,-0.22),(.desk,0.4105,-0.7995),(.chair,0.54,0.0201),(.plant,-0.8425,0.6975),(.frame,-0.5,-0.9775),(.shelf,0.4,-0.919)] {
   let n=entity(k);n.simdPosition=[x,k.hangsOnWall ? k.hangingHeight:0,z];room.addChildNode(n)
  }
  try save(snapshot(room,target:[0,0.72,0],scale:1.68,size:CGSize(width:1200,height:1100)),dest+"/room-b.png")
  print("Rendered B furniture previews and room")
 }
}
