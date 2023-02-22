/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The host app renderer.
*/


import ARKit
import Metal
import MetalKit
import QuartzCore
import SceneKit
import SpriteKit
import SwiftUI

var pointsWithArms: [SCNVector3] = [SCNVector3]()
var filepathURL : URL = URL(fileURLWithPath: "")

final class Renderer {
    
    
    // Maximum number of points we store in the point cloud
   //  private let maxPoints = 2500_000
//    200000
    private let maxPoints = 200000
    // Number of sample points on the grid
    private let numGridPoints = 3000
    // Particle's size in pixels
    private var particleSize: Float = 15
    // We only use landscape orientation in this app
    private let orientation = UIInterfaceOrientation.portrait
    // Camera's threshold values for detecting when the camera moves so that we can accumulate the points
    private let cameraRotationThreshold = cos(2 * .degreesToRadian)
    private let cameraTranslationThreshold: Float = pow(0.02, 2)   // (meter-squared)
    // The max number of command buffers in flight
    private let maxInFlightBuffers = 3
    
    private lazy var rotateToARCamera = Self.makeRotateToARCameraMatrix(orientation: orientation)
    var session: ARSession
    
    // Metal objects and textures
    private let device: MTLDevice
    private let library: MTLLibrary
    private let renderDestination: RenderDestinationProvider
    private let relaxedStencilState: MTLDepthStencilState
    private let depthStencilState: MTLDepthStencilState
    private let commandQueue: MTLCommandQueue
    private lazy var unprojectPipelineState = makeUnprojectionPipelineState()!
    private lazy var rgbPipelineState = makeRGBPipelineState()!
    private lazy var particlePipelineState = makeParticlePipelineState()!
    // texture cache for captured image
    private lazy var textureCache = makeTextureCache()
    private var capturedImageTextureY: CVMetalTexture?
    private var capturedImageTextureCbCr: CVMetalTexture?
    private var depthTexture: CVMetalTexture?
    private var confidenceTexture: CVMetalTexture?
    
    // Multi-buffer rendering pipeline
    private let inFlightSemaphore: DispatchSemaphore
    private var currentBufferIndex = 0
    var tag: Int = 0
    // The current viewport size
    private var viewportSize = CGSize()
    // The grid of sample points
    private lazy var gridPointsBuffer = MetalBuffer<Float2>(device: device,
                                                            array: makeGridPoints(),
                                                            index: kGridPoints.rawValue, options: [])
    
    // RGB buffer
    private lazy var rgbUniforms: RGBUniforms = {
        var uniforms = RGBUniforms()
        uniforms.radius = rgbRadius
        uniforms.viewToCamera.copy(from: viewToCamera)
        uniforms.viewRatio = Float(viewportSize.width / viewportSize.height)
        return uniforms
    }()
    private var rgbUniformsBuffers = [MetalBuffer<RGBUniforms>]()
    // Point Cloud buffer
    private lazy var pointCloudUniforms: PointCloudUniforms = {
        var uniforms = PointCloudUniforms()
        uniforms.maxPoints = Int32(maxPoints)
        uniforms.confidenceThreshold = Int32(confidenceThreshold)
        uniforms.particleSize = particleSize
        uniforms.cameraResolution = cameraResolution
        return uniforms
    }()
    private var pointCloudUniformsBuffers = [MetalBuffer<PointCloudUniforms>]()
    // Particles buffer
    private var particlesBuffer: MetalBuffer<ParticleUniforms>
    private var currentPointIndex = 0
    private var currentPointCount = 0
    
    // Camera data
    private var sampleFrame: ARFrame { session.currentFrame! }
    private lazy var cameraResolution = Float2(Float(sampleFrame.camera.imageResolution.width), Float(sampleFrame.camera.imageResolution.height))
    private lazy var viewToCamera = sampleFrame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
    private lazy var lastCameraTransform = sampleFrame.camera.transform
    
    // interfaces
    var confidenceThreshold = 2 {
        didSet {
            // apply the change for the shader
            pointCloudUniforms.confidenceThreshold = Int32(confidenceThreshold)
        }
    }
    
    var rgbRadius: Float = 2.5 {
        didSet {
            // apply the change for the shader
            print("rgbRadius")
            rgbUniforms.radius = rgbRadius
        }
    }
    // save and export
   
    var renderingEnable: Bool = false
    var sessionstop: Bool = false
    var issessioninitilize: Bool = false
    var isSavingFile = true {
        didSet {
            print("isSavingFile:\(isSavingFile)")
        }
    }

    var convertedScene = SCNScene()

    var showrenderingScreen: Bool = false

    //  var pathnameofscnfile: String = ""

    var pathnameofscnfile: String = ""
    var pathnameofscnfilepath: String = ""
    var pathnameofplyfile: String = ""
    var allpoint = [simd_float3]()
    var finalPoints = [simd_float3]()
    var finalPoint = [simd_float3]()
    var smoothpoints = [simd_float3]()
    var listofallbreakpoint = [[simd_float3]]()

    // Arm cutting
    var deltaHeight: Float = 0.01
    var pointCountThreshold = 2
    var xIncrement: Float = 0.01
    var topMostPoint: Float = 0
    var bottomMostPoint: Float = 0
    var indexofshoulder = 0
    
    @ObservedObject var sharedViewModel: SharedViewModel
    
    init(session: ARSession, metalDevice device: MTLDevice, renderDestination: RenderDestinationProvider) {
        self.session = session
        self.device = device
        self.renderDestination = renderDestination
        
        library = device.makeDefaultLibrary()!
        commandQueue = device.makeCommandQueue()!
        
        // initialize our buffers
        for _ in 0 ..< maxInFlightBuffers {
            rgbUniformsBuffers.append(.init(device: device, count: 1, index: 0))
            pointCloudUniformsBuffers.append(.init(device: device, count: 1, index: kPointCloudUniforms.rawValue))
        }
        particlesBuffer = .init(device: device, count: maxPoints, index: kParticleUniforms.rawValue)
        
        // rbg does not need to read/write depth
        let relaxedStateDescriptor = MTLDepthStencilDescriptor()
        relaxedStencilState = device.makeDepthStencilState(descriptor: relaxedStateDescriptor)!
        
        // setup depth test for point cloud
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = .lessEqual
        depthStateDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStateDescriptor)!
        
        inFlightSemaphore = DispatchSemaphore(value: maxInFlightBuffers)
        sharedViewModel = SharedViewModel()
    }
    
    func drawRectResized(size: CGSize) {
        print("rgbRadius1")
        viewportSize = size
    }
   
    private func updateCapturedImageTextures(frame: ARFrame) {
        // Create two textures (Y and CbCr) from the provided frame's captured image
        let pixelBuffer = frame.capturedImage
        guard CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else {
            return
        }
        
        capturedImageTextureY = makeTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0)
        capturedImageTextureCbCr = makeTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1)
    }
    
    private func updateDepthTextures(frame: ARFrame) -> Bool {
        guard let depthMap = frame.sceneDepth?.depthMap,
            let confidenceMap = frame.sceneDepth?.confidenceMap else {
                return false
        }
        
        depthTexture = makeTexture(fromPixelBuffer: depthMap, pixelFormat: .r32Float, planeIndex: 0)
        confidenceTexture = makeTexture(fromPixelBuffer: confidenceMap, pixelFormat: .r8Uint, planeIndex: 0)
        
        return true
    }
    
    private func update(frame: ARFrame) {
        // frame dependent info
        let camera = frame.camera
        let cameraIntrinsicsInversed = camera.intrinsics.inverse
        let viewMatrix = camera.viewMatrix(for: orientation)
        let viewMatrixInversed = viewMatrix.inverse
        let projectionMatrix = camera.projectionMatrix(for: orientation, viewportSize: viewportSize, zNear: 0.001, zFar: 0)
        pointCloudUniforms.viewProjectionMatrix = projectionMatrix * viewMatrix
        pointCloudUniforms.localToWorld = viewMatrixInversed * rotateToARCamera
        pointCloudUniforms.cameraIntrinsicsInversed = cameraIntrinsicsInversed
    }
    
    func draw() {
        guard let currentFrame = session.currentFrame,
            let renderDescriptor = renderDestination.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor) else {
                return
        }
        
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        commandBuffer.addCompletedHandler { [weak self] commandBuffer in
            if let self = self {
                self.inFlightSemaphore.signal()
            }
        }
        
        // update frame data
        update(frame: currentFrame)
        updateCapturedImageTextures(frame: currentFrame)
        
        // handle buffer rotating
        currentBufferIndex = (currentBufferIndex + 1) % maxInFlightBuffers
        pointCloudUniformsBuffers[currentBufferIndex][0] = pointCloudUniforms
        
        if shouldAccumulate(frame: currentFrame), updateDepthTextures(frame: currentFrame) {
            accumulatePoints(frame: currentFrame, commandBuffer: commandBuffer, renderEncoder: renderEncoder)
        }
        
        // check and render rgb camera image
        if rgbUniforms.radius > 0 {

            var retainingTextures = [capturedImageTextureY, capturedImageTextureCbCr]
            commandBuffer.addCompletedHandler { buffer in
                retainingTextures.removeAll()
            }
            rgbUniformsBuffers[currentBufferIndex][0] = rgbUniforms
            
            renderEncoder.setDepthStencilState(relaxedStencilState)
            renderEncoder.setRenderPipelineState(rgbPipelineState)
            renderEncoder.setVertexBuffer(rgbUniformsBuffers[currentBufferIndex])
            renderEncoder.setFragmentBuffer(rgbUniformsBuffers[currentBufferIndex])
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(capturedImageTextureY!), index: Int(kTextureY.rawValue))
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(capturedImageTextureCbCr!), index: Int(kTextureCbCr.rawValue))
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }
       
        // render particles
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(particlePipelineState)
        renderEncoder.setVertexBuffer(pointCloudUniformsBuffers[currentBufferIndex])
        renderEncoder.setVertexBuffer(particlesBuffer)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: currentPointCount)
        renderEncoder.endEncoding()
            
        commandBuffer.present(renderDestination.currentDrawable!)
        commandBuffer.commit()
    }
    
    private func shouldAccumulate(frame: ARFrame) -> Bool {
        let cameraTransform = frame.camera.transform
        return currentPointCount == 0
            || dot(cameraTransform.columns.2, lastCameraTransform.columns.2) <= cameraRotationThreshold
            || distance_squared(cameraTransform.columns.3, lastCameraTransform.columns.3) >= cameraTranslationThreshold
    }
    
    private func accumulatePoints(frame: ARFrame, commandBuffer: MTLCommandBuffer, renderEncoder: MTLRenderCommandEncoder) {
        pointCloudUniforms.pointCloudCurrentIndex = Int32(currentPointIndex)
        
        var retainingTextures = [capturedImageTextureY, capturedImageTextureCbCr, depthTexture, confidenceTexture]
        commandBuffer.addCompletedHandler { buffer in
            retainingTextures.removeAll()
        }
        
        renderEncoder.setDepthStencilState(relaxedStencilState)
        renderEncoder.setRenderPipelineState(unprojectPipelineState)
        renderEncoder.setVertexBuffer(pointCloudUniformsBuffers[currentBufferIndex])
        renderEncoder.setVertexBuffer(particlesBuffer)
        renderEncoder.setVertexBuffer(gridPointsBuffer)
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(capturedImageTextureY!), index: Int(kTextureY.rawValue))
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(capturedImageTextureCbCr!), index: Int(kTextureCbCr.rawValue))
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(depthTexture!), index: Int(kTextureDepth.rawValue))
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(confidenceTexture!), index: Int(kTextureConfidence.rawValue))
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: gridPointsBuffer.count)
        
        currentPointIndex = (currentPointIndex + gridPointsBuffer.count) % maxPoints
        currentPointCount = min(currentPointCount + gridPointsBuffer.count, maxPoints)
        lastCameraTransform = frame.camera.transform
    }
}

// MARK: - Metal Helpers

private extension Renderer {
    func makeUnprojectionPipelineState() -> MTLRenderPipelineState? {
        guard let vertexFunction = library.makeFunction(name: "unprojectVertex") else {
                return nil
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.isRasterizationEnabled = false
        descriptor.depthAttachmentPixelFormat = renderDestination.depthStencilPixelFormat
        descriptor.colorAttachments[0].pixelFormat = renderDestination.colorPixelFormat
        
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    func makeRGBPipelineState() -> MTLRenderPipelineState? {
        guard let vertexFunction = library.makeFunction(name: "rgbVertex"),
            let fragmentFunction = library.makeFunction(name: "rgbFragment") else {
                return nil
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.depthAttachmentPixelFormat = renderDestination.depthStencilPixelFormat
        descriptor.colorAttachments[0].pixelFormat = renderDestination.colorPixelFormat
        
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    func makeParticlePipelineState() -> MTLRenderPipelineState? {
        guard let vertexFunction = library.makeFunction(name: "particleVertex"),
            let fragmentFunction = library.makeFunction(name: "particleFragment") else {
                return nil
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.depthAttachmentPixelFormat = renderDestination.depthStencilPixelFormat
        descriptor.colorAttachments[0].pixelFormat = renderDestination.colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    /// Makes sample points on camera image, also precompute the anchor point for animation
    func makeGridPoints() -> [Float2] {
        let gridArea = cameraResolution.x * cameraResolution.y
        let spacing = sqrt(gridArea / Float(numGridPoints))
        let deltaX = Int(round(cameraResolution.x / spacing))
        let deltaY = Int(round(cameraResolution.y / spacing))
        
        var points = [Float2]()
        for gridY in 0 ..< deltaY {
            let alternatingOffsetX = Float(gridY % 2) * spacing / 2
            for gridX in 0 ..< deltaX {
                let cameraPoint = Float2(alternatingOffsetX + (Float(gridX) + 0.5) * spacing, (Float(gridY) + 0.5) * spacing)
                
                points.append(cameraPoint)
            }
        }
        
        return points
    }
    
    func makeTextureCache() -> CVMetalTextureCache {
        // Create captured image texture cache
        var cache: CVMetalTextureCache!
        CVMetalTextureCacheCreate(nil, nil, device, nil, &cache)
        
        return cache
    }
    
    func makeTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture? = nil
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
        
        if status != kCVReturnSuccess {
            texture = nil
        }

        return texture
    }
    
    static func cameraToDisplayRotation(orientation: UIInterfaceOrientation) -> Int {
        switch orientation {
        case .landscapeLeft:
            return 180
        case .portrait:
            return 90
        case .portraitUpsideDown:
            return -90
        default:
            return 0
        }
    }
    
    static func makeRotateToARCameraMatrix(orientation: UIInterfaceOrientation) -> matrix_float4x4 {
        // flip to ARKit Camera's coordinate
        let flipYZ = matrix_float4x4(
            [1, 0, 0, 0],
            [0, -1, 0, 0],
            [0, 0, -1, 0],
            [0, 0, 0, 1] )

        let rotationAngle = Float(cameraToDisplayRotation(orientation: orientation)) * .degreesToRadian
        return flipYZ * matrix_float4x4(simd_quaternion(rotationAngle, Float3(0, 0, 1)))
    }
   
}

// MARK: - Pointcloud processing and save

extension Renderer {

    func particleBufferIn() {
        particlesBuffer = .init(device: device, count: maxPoints, index: 1)
        particleSize = 15
    }
    
    static func RemoveNoisyPoints(_ points: [SCNVector3], _ rh: Float = 0.02, _ rV: Float = 0.01) -> [SCNVector3]
    {
        var newPoints = [SCNVector3]()
        var pointsAtHeightsList = GetPointsHeightWise(points)
        
        for hIndex in stride(from: 0, to: pointsAtHeightsList.count, by: 1)
        {
            while(pointsAtHeightsList[hIndex].count > 0)
            {
                let point = pointsAtHeightsList[hIndex][0]
                pointsAtHeightsList[hIndex].remove(at: 0)
                
                var localPoints = [SCNVector3]()
                var localPointsIndex = [Int]()
                var localPoint0U = [SCNVector3]()
                var localPoint0UIndex = [Int]()
                var localPoint0D = [SCNVector3]()
                var localPoint0DIndex = [Int]()
                
                localPoints.append(point)
                
                let pt1 = SCNVector3(x: point.x, y: 0, z: point.z)
                
                var idx = 0
                for pt in pointsAtHeightsList[hIndex]
                {
                    let pt2 = SCNVector3(x: pt.x, y: 0, z: pt.z)
                    if pt1.distance(toVector: pt2) < rh && abs(pt.y - point.y) < rV
                    {
                        localPoints.append(pt)
                        localPointsIndex.append(idx)
                    }
                    idx += 1
                }
                
                idx = 0
                if hIndex > 0
                {
                    for pt in pointsAtHeightsList[hIndex - 1]
                    {
                        let pt2 = SCNVector3(x: pt.x, y: 0, z: pt.z)
                        if pt1.distance(toVector: pt2) < rh && abs(pt.y - point.y) < rV
                        {
                            localPoint0U.append(pt)
                            localPoint0UIndex.append(idx)
                        }
                        idx += 1
                    }
                }
                
                idx = 0
                if (hIndex < pointsAtHeightsList.count - 1)
                {
                    for pt in pointsAtHeightsList[hIndex + 1]
                    {
                        let pt2 = SCNVector3(x: pt.x, y: 0, z: pt.z)
                        if pt1.distance(toVector: pt2) < rh && abs(pt.y - point.y) < rV
                        {
                            localPoint0D.append(pt)
                            localPoint0DIndex.append(idx)
                        }
                        idx += 1
                    }
                }
                
                
                if localPoints.count + localPoint0U.count + localPoint0D.count > 5
                {
                    newPoints.append(contentsOf: localPoints)
                    newPoints.append(contentsOf: localPoint0U)
                    newPoints.append(contentsOf: localPoint0D)
                }
                
                localPointsIndex = localPointsIndex.reversed()
                localPoint0UIndex = localPoint0UIndex.reversed()
                localPoint0DIndex = localPoint0DIndex.reversed()
                
                for idx in localPointsIndex
                {
                    pointsAtHeightsList[hIndex].remove(at: idx)
                }
                
                for idx in localPoint0UIndex
                {
                    pointsAtHeightsList[hIndex - 1].remove(at: idx)
                }
                
                for idx in localPoint0DIndex
                {
                    pointsAtHeightsList[hIndex + 1].remove(at: idx)
                }
            }
        }
        
        return newPoints
    }
    
    
    public static func GetPointsHeightWise(_ points: [SCNVector3]) -> [[SCNVector3]]
    {
        var pointsAtHeightsList = [[SCNVector3]]()
        
        if points.count == 0 || points.count < 2
        {
            return pointsAtHeightsList
        }
        
        var newPoints = [SCNVector3]()
        for point in points
        {
            newPoints.append(point)
        }
        
        newPoints.sort { $0.y > $1.y }
        
        var currentHeight = newPoints[0].y
        var lastHeightStartIndex = 0
        
        for i in stride(from: 0, to: newPoints.count, by: 1)
        {
            if newPoints[i].y <= currentHeight - 0.01
            {
                var pointsAtAHeight = [SCNVector3]()
                
                for j in stride(from: lastHeightStartIndex, to: i, by: 1)
                {
                    pointsAtAHeight.append(newPoints[j])
                }
                
                if pointsAtAHeight.count == 0
                {
                    pointsAtAHeight = [SCNVector3]()
                }
                
                pointsAtHeightsList.append(pointsAtAHeight)
                lastHeightStartIndex = i
                currentHeight = currentHeight - 0.01
            }
        }
        
        if lastHeightStartIndex < newPoints.count
        {
            var pointsAtAHeight = [SCNVector3]()
            let diff = abs(newPoints.count-lastHeightStartIndex)
            for j in stride(from: lastHeightStartIndex, to: lastHeightStartIndex + diff, by: 1)
            {
                pointsAtAHeight.append(newPoints[j])
            }
            if pointsAtAHeight.count == 0
            {
                pointsAtAHeight = [SCNVector3]()
            }
            pointsAtHeightsList.append(pointsAtAHeight)
        }
        
        return pointsAtHeightsList
    }
    
    
    func removenoisypointnew() {
        allpoint = [simd_float3]()
        for i in 1 ..< currentPointCount {
            // 3 newsavedparticlesBuffer
            allpoint.append([particlesBuffer[i].position.x, particlesBuffer[i].position.y, particlesBuffer[i].position.z])
        }

        
        allpoint.removeDuplicates()
        allpoint.sort { $0.y != $1.y ? $0.y > $1.y : $0.x < $1.x }
       //  print("value: \(allpoint[0].y - allpoint[1].y)")
        print("all point count\(allpoint.count)")
        while allpoint.count > 1 {
            var listofparsepoint: [simd_float3] = []
            var i = 0

            var indexOfPointsparse = [Int]()
            let count = allpoint.count
            while (allpoint[0].y - allpoint[i].y) < 0.1 {
                listofparsepoint.append(allpoint[i])
                indexOfPointsparse.append(i)
                if count <= i + 1 {
                    break
                }
                i = i + 1
            }
            let v = Array(indexOfPointsparse.sorted().reversed())
            for k in 0 ..< indexOfPointsparse.count {
                allpoint.remove(at: v[k])
            }
            // print("count \(listofparsepoint.count)+\(allpoint.count)")
            while listofparsepoint.count > 0 {
                var listofanothepoint: [simd_float3] = []
                var indexOfPointsToRemove = [Int]()
                var listofanothepointsmooth: [simd_float3] = []

                for i in 1 ..< listofparsepoint.count {
                    // let distances = distance(allpoint[j], [particlesBuffer[i].position.x, particlesBuffer[i].position.y, particlesBuffer[i].position.z])
                    let distances = distance(listofparsepoint[0], listofparsepoint[i])

                    if distances < 0.02 {
                        if (listofparsepoint[0].y - listofparsepoint[i].y) < 0.01 {
                            listofanothepointsmooth.append(listofparsepoint[i])
                        }
                        listofanothepoint.append(listofparsepoint[i])

                        indexOfPointsToRemove.append(i)
                    }
                }
                if listofanothepoint.count <= 5 {
                    listofparsepoint.remove(at: 0)

                    continue
                } else {
                    finalPoints.append(listofparsepoint[0])
                    finalPoints.append(contentsOf: listofanothepoint)
                }
                let v = Array(indexOfPointsToRemove.sorted().reversed())
                for k in 0 ..< indexOfPointsToRemove.count {
                    listofparsepoint.remove(at: v[k])
                }
                listofparsepoint.remove(at: 0)
            }
        }
        print("final count\(finalPoints.count)")
    }
    func changeoriginnew() {
        Helper().savePathnameToKeychain(pathname: "")
        allpoint = [simd_float3]()
        for i in 1 ..< currentPointCount {
            // 3 newsavedparticlesBuffer
            finalPoint.append([particlesBuffer[i].position.x, particlesBuffer[i].position.y, particlesBuffer[i].position.z])
        }
        finalPoint.removeDuplicates()
        removenoisypointnew()

        var sum = finalPoints[0]
        var avg = finalPoints[0]
        let count = finalPoints.count
        for i in 1 ..< count {
            // 3 newsavedparticlesBuffer
            sum = sum + finalPoints[i]
        }
        avg.x = sum.x / Float(count)
        avg.y = sum.y / Float(count)
        avg.z = sum.z / Float(count)
        for i in 1 ..< count {
            // 3 newsavedparticlesBuffer
            finalPoints[i] = finalPoints[i] - avg
        }
        print("all point are shifted")
        isSavingFile = false
        var sum2 = finalPoint[0]
        var avg2 = finalPoint[0]
        let count2 = finalPoint.count
        for i in 1 ..< count2 {
            // 3 newsavedparticlesBuffer
            sum2 = sum2 + finalPoint[i]
        }
        avg2.x = sum2.x / Float(count2)
        avg2.y = sum2.y / Float(count2)
        avg2.z = sum2.z / Float(count2)
        for i in 1 ..< count2 {
            // 3 newsavedparticlesBuffer
            finalPoint[i] = finalPoint[i] - avg
        }
        print("all point are shifted2")
        isSavingFile = false
        pointSmoothing()
    }


    func pointSmoothing() {
        var totalPoints = [simd_float3]()
        totalPoints.append(contentsOf: finalPoints)

        while totalPoints.count > 1 {
            var listofparsepoint: [simd_float3] = []
            var i = 0

            var indexOfPointsparse = [Int]()
            let count = totalPoints.count
            while (totalPoints[0].y - totalPoints[i].y) < 0.005 {
                listofparsepoint.append(totalPoints[i])
                indexOfPointsparse.append(i)
                if count <= i + 1 {
                    listofallbreakpoint.append(listofparsepoint)
                    break
                }
                i = i + 1
            }
            listofallbreakpoint.append(listofparsepoint)

            let v = Array(indexOfPointsparse.sorted().reversed())
            for k in 0 ..< indexOfPointsparse.count {
                totalPoints.remove(at: v[k])
            }
            // print("count \(listofparsepoint.count)+\(totalPoints.count)")
            while listofparsepoint.count > 0 {
                var listofanothepoint: [simd_float3] = []
                var indexOfPointsToRemove = [Int]()
                for i in 1 ..< listofparsepoint.count {
                    // let distances = distance(allpoint[j], [particlesBuffer[i].position.x, particlesBuffer[i].position.y, particlesBuffer[i].position.z])
                    let distances = distance(listofparsepoint[0], listofparsepoint[i])

                    if distances < 0.01 {
                        listofanothepoint.append(listofparsepoint[i])
                        indexOfPointsToRemove.append(i)
                    }
                }
                if listofanothepoint.count <= 5 {
                    listofparsepoint.remove(at: 0)

                    continue
                } else {
                    var sum = listofparsepoint[0]
                    var avg = listofparsepoint[0]
                    let count = listofanothepoint.count
                    for i in 0 ..< count {
                        // 3 newsavedparticlesBuffer
                        sum = sum + listofanothepoint[i]
                    }
                    avg.x = sum.x / Float(count + 1)
                    avg.y = sum.y / Float(count + 1)
                    avg.z = sum.z / Float(count + 1)
                    smoothpoints.append(avg)
                }
                let v = Array(indexOfPointsToRemove.sorted().reversed())
                for k in 0 ..< indexOfPointsToRemove.count {
                    listofparsepoint.remove(at: v[k])
                }
                listofparsepoint.remove(at: 0)
            }
        }
    }
    // arm cutting algorithm

    func getAveregedOuterPoints(pointAtAGivenY: [simd_float3]) -> [simd_float3] {
        // let the code run even if there are no points at point at givenY
        // in the case above it will return empty list which means no points
        if pointAtAGivenY.count == 0 {
            let list = [simd_float3]()
            return list
        }
        var avaragedfinalpoint = [simd_float3]()
        var smoothfinalpoint = [simd_float3]()
        var sum = pointAtAGivenY[0]
        var centroid = pointAtAGivenY[0]
        let count = pointAtAGivenY.count
        for i in 0 ..< count {
            sum = sum + pointAtAGivenY[i]
        }
        centroid.x = sum.x / Float(count + 1)
        centroid.y = sum.y / Float(count + 1)
        centroid.z = sum.z / Float(count + 1)
        for i in 0 ..< count {
            avaragedfinalpoint.append(pointAtAGivenY[i] - centroid)
        }

        avaragedfinalpoint.sort { atan2($0.x, $0.z) < atan2($1.x, $1.z) }

        // tempLoop to check only  // can be optimized using sorted list
        var indexofLastMaxanglePoints = 0
        let angleIncrementPerLoop: Float = 6
        var angleToCheck: Float = -180
        while angleToCheck < 180 {
            var pointsAtAnAngle = [simd_float3]()
            while indexofLastMaxanglePoints < avaragedfinalpoint.count {
                if ((180 / .pi) * atan2(avaragedfinalpoint[indexofLastMaxanglePoints].x, avaragedfinalpoint[indexofLastMaxanglePoints].z)) >= (angleToCheck + angleIncrementPerLoop)
                {
                    break
                }
                pointsAtAnAngle.append(avaragedfinalpoint[indexofLastMaxanglePoints])
                indexofLastMaxanglePoints += 1
            }
            // List<Vector3> pointsAtAnAngle2 = new List<Vector3>();
            if pointsAtAnAngle != nil && pointsAtAnAngle.count > 0 {
                var sum1 = avaragedfinalpoint[0]
                var avgPoint = avaragedfinalpoint[0]
                let count = avaragedfinalpoint.count
                for i in 0 ..< count {
                    // 3 newsavedparticlesBuffer
                    sum1 = sum1 + avaragedfinalpoint[i]
                }
                avgPoint.x = sum1.x / Float(count + 1)
                avgPoint.y = sum1.y / Float(count + 1)
                avgPoint.z = sum1.z / Float(count + 1)
                smoothfinalpoint.append(avgPoint)
            }
            angleToCheck += angleIncrementPerLoop
        }
        return smoothfinalpoint
    }
    
    // pass sorted array of all point to find shoulder function
    func findSholder(pointarray: [simd_float3]) -> Float {
        var currentHeight = pointarray[0].y
        let allpointcount = pointarray.count
        var totalPoints = [simd_float3]()
        totalPoints.append(contentsOf: pointarray)
        topMostPoint = pointarray[0].y
        bottomMostPoint = pointarray[allpointcount - 1].y
        print("currentHeight \(currentHeight):: \(topMostPoint - 0.20)")
        print("listofallbreakpoint \(listofallbreakpoint.count)")
        while currentHeight > topMostPoint - 0.20 {
            var pointsAtAGivenY: [simd_float3] = []
            pointsAtAGivenY = totalPoints.filter { $0.y < currentHeight && $0.y > currentHeight - deltaHeight }
            let outerSmPoints = getAveregedOuterPoints(pointAtAGivenY: pointsAtAGivenY)

            if outerSmPoints.count >= 40 {
                
                break
            }
        
            currentHeight -= Float(deltaHeight)
            print("topMostPoint kkk\(topMostPoint) bottomMostPoint\(bottomMostPoint) currentHeight\(currentHeight)")
        }
        
        while currentHeight > topMostPoint - 0.3 {
            var pointsAtAGivenY: [simd_float3] = []
            
            pointsAtAGivenY = totalPoints.filter { $0.y < currentHeight && $0.y > currentHeight - deltaHeight }
            
            var pointsBelowGivenY = [simd_float3]()
            pointsAtAGivenY = totalPoints.filter { $0.y < currentHeight - 0.05 && $0.y > currentHeight - deltaHeight - 0.05 }
            if pointsAtAGivenY.count > 0 && pointsBelowGivenY.count > 0 {
                pointsAtAGivenY.sort { $0.x < $1.x }
                pointsBelowGivenY.sort { $0.x < $1.x }
                var widthAtAGivenY = pointsAtAGivenY[0].x - pointsAtAGivenY[pointsAtAGivenY.count - 1].x
                var widthBelowGivenY = pointsBelowGivenY[0].x - pointsBelowGivenY[pointsBelowGivenY.count - 1].x
                if abs(widthBelowGivenY) > 2 * abs(widthAtAGivenY) {
                    return currentHeight - 0.05
                }
            } else {
                
                break
            }
           
            currentHeight -= Float(deltaHeight)
        }
        print("indexofshoulder1 \(indexofshoulder)")
        print("topMostPoint qqq\(topMostPoint) bottomMostPoint\(bottomMostPoint) currentHeight\(currentHeight)")
        return 0
    }
    
    func CutArmsNew(allPoints: [simd_float3]) -> [simd_float3] {
        var allheightdata = [[[simd_float3]]]()
        var allPointsCopy = [simd_float3]()

        var currentHeight: Float = findSholder(pointarray: allPoints)
        topMostPoint = allPoints[0].y
        bottomMostPoint = allPoints[allPoints.count - 1].y
        
        // var currentHeight : Float = 0
        if currentHeight == 0 {
            currentHeight = topMostPoint - 0.1
        }
        print("allPointsCopy \(allPoints.count)")
        allPointsCopy = allPoints.filter { $0.y > currentHeight }
        print("coallPointsCopy \(allPointsCopy.count) :: allPointsCopy \(allPoints.count)")
        while currentHeight > bottomMostPoint {
            var pointsAtGivenY = [simd_float3]()
            
            pointsAtGivenY = allPoints.filter { $0.y <= currentHeight && $0.y > currentHeight - deltaHeight }
            print("currentheight : \(currentHeight) :: pointsAtGivenY\(pointsAtGivenY.count)")
            var allCrossSectionsAtThisHeight = [[simd_float3]]()
            if pointsAtGivenY.count > 0 {
                pointsAtGivenY.sort { $0.x < $1.x }
                var currentXCoordinate: Float = pointsAtGivenY[0].x

                while currentXCoordinate <= pointsAtGivenY[pointsAtGivenY.count - 1].x + 0.1 {
                    var pointsAtParticularX = [simd_float3]()
                    pointsAtParticularX = pointsAtGivenY.filter { $0.x >= currentXCoordinate && $0.x < currentXCoordinate + xIncrement }

                    if pointsAtParticularX.count > pointCountThreshold {
                        var cData = [simd_float3]()
                        while currentXCoordinate <= pointsAtGivenY[pointsAtGivenY.count - 1].x + 0.1 {
                            var pointsAtParticularCrossSectionX = pointsAtGivenY.filter { $0.x >= currentXCoordinate && $0.x < currentXCoordinate + xIncrement }

                            if pointsAtParticularCrossSectionX.count > pointCountThreshold {
                                cData.append(contentsOf: pointsAtParticularCrossSectionX)
                                
                            } else {
                                print("cData \(cData.count)")
                                allCrossSectionsAtThisHeight.append(cData)
                                print("allCrossSectionsAtThisHeight2 : \(allCrossSectionsAtThisHeight.count)")
                                currentXCoordinate += xIncrement
                                break
                            }
                            currentXCoordinate += xIncrement
                        }
                        
                    }
                    currentXCoordinate += xIncrement
                }
            }
            print("allCrossSectionsAtThisHeight1: \(allCrossSectionsAtThisHeight.count)")
            allheightdata.append(allCrossSectionsAtThisHeight)
            currentHeight -= deltaHeight
        }

        var firstArmPointDetected: Bool = false
        var firstArmPointIndex: Int = -1
        var leftExtreme: Float = 0
        var rightExtreme: Float = 0

        for j in 0 ..< allheightdata.count {
            if firstArmPointDetected && firstArmPointIndex != -1 {
                if j - firstArmPointIndex <= 10 && allheightdata[j].count == 3 {
                    var maxPointIndex: Int = 0
                    if allheightdata[j][1].count > allheightdata[j][maxPointIndex].count {
                        maxPointIndex = 1
                    }
                    if allheightdata[j][2].count > allheightdata[j][maxPointIndex].count {
                        maxPointIndex = 2
                    }

                    allheightdata[j][0].sort { $0.x < $1.x }
                    allheightdata[j][1].sort { $0.x < $1.x }
                    allheightdata[j][2].sort { $0.x < $1.x }

                    allPointsCopy.append(contentsOf: allheightdata[j][maxPointIndex])

                    if maxPointIndex == 1 {
                        leftExtreme = allheightdata[j][0][allheightdata[j][0].count - 1].x
                        rightExtreme = allheightdata[j][2][0].x
                    } else if maxPointIndex == 0 {
                        rightExtreme = allheightdata[j][1][0].x
                    } else {
                        leftExtreme = allheightdata[j][1][allheightdata[j][1].count - 1].x
                    }
                } else {
                    for p in 0 ..< allheightdata[j].count {
                        var pointInside = [simd_float3]()
                        pointInside = allheightdata[j][p].filter { $0.x > leftExtreme && $0.x < rightExtreme }
                        allPointsCopy.append(contentsOf: pointInside)
                    }
                }
            }
            if allheightdata[j].count == 3 && !firstArmPointDetected {
                allheightdata[j][1].sort { $0.x < $1.x }

                allPointsCopy.append(contentsOf: allheightdata[j][1])
                allPointsCopy.removeAll { $0.x > allheightdata[j][1][allheightdata[j][1].count - 1].x && $0.y > allheightdata[j][1][allheightdata[j][1].count - 1].y }
                allPointsCopy.removeAll { $0.x < allheightdata[j][1][0].x && $0.y > allheightdata[j][1][0].y }

                firstArmPointDetected = true
                firstArmPointIndex = j

                leftExtreme = allheightdata[j][0][allheightdata[j][0].count - 1].x
                rightExtreme = allheightdata[j][2][0].x
            }

            if firstArmPointDetected == false {
                for i in 0 ..< allheightdata[j].count {
                    allPointsCopy.append(contentsOf: allheightdata[j][i])
                }
            }
        }

        return allPointsCopy
    }
    
    func savePointsPCDFormat()
    {
        var finalPoints = [simd_float3]()
        for i in stride(from: 0, to: currentPointCount, by: 1)
        {
            finalPoints.append([particlesBuffer[i].position.x, particlesBuffer[i].position.y, particlesBuffer[i].position.z])
        }
        finalPoints.removeDuplicates()
        let count = finalPoints.count
        print("final count", count)
        let avg = StaticAlgos.GetCentroid(finalPoints)
        
        for i in stride(from: 0, to: count, by: 1)
        {
            finalPoints[i] = finalPoints[i] - avg
        }
        isSavingFile = false
        var finalPointsPCD = [SCNVector3]()
        
        for i in stride(from: 0, to: finalPoints.count, by: 1)
        {
            finalPointsPCD.append(SCNVector3(x: finalPoints[i].x, y: finalPoints[i].y, z: finalPoints[i].z))
        }
        
        
        for i in stride(from: 0, to: finalPointsPCD.count, by: 1)
        {
            finalPointsPCD[i].z *= -1
        }
        
//        let date = Date()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "YYYYMMdd_HHmmss"
////        let PCD_Folder_Name = dateFormatter.string(from: date)
//
//        let docURL = GetDocumentDirectoryUrl()
//        let dataPath = docURL.appendingPathComponent("Scans")
//
//        if !FileManager.default.fileExists(atPath: dataPath.path)
//        {
//            do
//            {
//                try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
//            }
//            catch
//            {
//                print("Cannot create a directory")
////                Debugger.show(type: DebugType.log, val: "Cannot create a directory", log: error.localizedDescription)
//            }
//        }
        //        let dataPath1 = dataPath.appendingPathComponent("PointCloudScans")
        //        if !FileManager.default.fileExists(atPath: dataPath1.path)
        //        {
        //            do
        //            {
        //                try FileManager.default.createDirectory(atPath: dataPath1.path, withIntermediateDirectories: true, attributes: nil)
        //            }
        //            catch
        //            {
        //                Debugger.show(type: DebugType.log, log: "Cannot create a directory1" + error.localizedDescription)
        //            }
        //        }
        
        //let UserFolderSavePath = dataPath1.appendingPathComponent(PCD_Folder_Name)
//        let UserFolderSavePath = dataPath.appendingPathComponent(PCD_Folder_Name)
//        if !FileManager.default.fileExists(atPath: UserFolderSavePath.path)
//        {
//            do
//            {
//                try FileManager.default.createDirectory(atPath: UserFolderSavePath.path, withIntermediateDirectories: true, attributes: nil)
//            }
//            catch
//            {
//                print(" Cannot create a directory")
////                Debugger.show(type: DebugType.log, val: "Cannot create a directory", log: error.localizedDescription)
//            }
//        }
//


//        var pathToRawPcd: String
////        var pathToRawPcdWithoutArms: String
////        var pathToNrmPcdWithArms: String
////        var pathToNrmPcdWithoutArms: String
//
//        let saveScanFolder = dataPath.absoluteString + "/"
//
//        //let appName = CustomerSession.Instance.AppName
//        pathToRawPcd =  saveScanFolder + "scans_\(dateFormatter.string(from: date)).pcd"
//        print("filepathURL1", pathToRawPcd)
//

        
       
        
//        let rawWithPoints = StaticAlgos.RemoveNoisyPoints(finalPointsPCD)
//        savePointsToDirectory(rawWithPoints, pathToRawPcd)
        
        let scn_Full_PCD = finalPointsPCD.map { p in
            simd_float3(Float(p.x), Float(p.y), Float(p.z))
              }
        
        
        let Floor_value = removeFloor(points: scn_Full_PCD)
        
        
        
        let all_point = Remove_points(full_pcd: finalPointsPCD, remove_point: Floor_value)
        
//        pointsWithArms = StaticAlgos.RemoveNoisyPoints(all_point)
        pointsWithArms = all_point
        
        
        

    }
    
    func Remove_points(full_pcd : [SCNVector3] , remove_point : Float)->[SCNVector3]{
        
        var Array_After_remove = [SCNVector3]()
        for i in stride (from: 1, to: full_pcd.count-1, by: 1){
            
            if full_pcd[i].y > remove_point{
                Array_After_remove.append(full_pcd[i])
            }
            
        }
        
        return Array_After_remove
        
    }
    
    func savePointsToDirectory(_ points: [SCNVector3], _ _filepath: String)
    {
        var filePath = ""
        if _filepath.hasPrefix("file://")
        {
            filePath = _filepath
        }
        else
        {
            filePath = "file://" + _filepath
        }
        let count = points.count
        var fileToWritecolor = ""
        let headerscolor =
        [
            "VERSION .7",
            "FIELDS x y z",
            "SIZE 4 4 4",
            "TYPE F F F",
            "COUNT 1 1 1",
            "WIDTH \(count)",
            "HEIGHT 1",
            "VIEWPOINT 0 0 0 1 0 0 0",
            "POINTS \(count)",
            "DATA ascii"
        ]
        
        for header in headerscolor
        {
            fileToWritecolor += header
            fileToWritecolor += "\r\n"
        }
        
        for i in stride(from: 0, to: count, by: 1)
        {
            let point = points[i]
            let pvValue = " \(point.x) \(point.y) \(point.z)"
            fileToWritecolor += pvValue
            fileToWritecolor += "\r\n"
        }
        
        do
        {
            filepathURL = URL(string: filePath)!
            print("filepathURL", filepathURL)
            try fileToWritecolor.write(to: filepathURL, atomically: true, encoding: String.Encoding.ascii)
        }
        catch
        {
            print("error in saving at",  "\(filePath)")
//            Debugger.show(type: DebugType.log, val: "error in saving at", log: "\(filePath)")
        }
    }
    
    

    
    
    func savePointsToFilenew() {
        /*
        var sortedpoint = [simd_float3]()
        sortedpoint.append(contentsOf: finalPoints)
        sortedpoint.sort { $0.y > $1.y }
        var cutarmpoint = CutArmsNew(allPoints: sortedpoint)
        // 2
        let countcutarm = cutarmpoint.count
        // 1
        var fileToWritecutarm = ""
        let headerscutarm = ["ply", "format ascii 1.0", "element vertex \(countcutarm)", "property float32 x", "property float32 y", "property float32 z", "element face 0", "property list uint8 int32 vertex_index", "end_header"]
        for header in headerscutarm {
            fileToWritecutarm += header
            fileToWritecutarm += "\r\n"
        }

        for i in 1 ..< countcutarm {
            // 3
            let pointcutarm = cutarmpoint[i]
            // 5
            let pvValuecutarm = "\(pointcutarm.x) \(pointcutarm.y) \(pointcutarm.z)"
            fileToWritecutarm += pvValuecutarm
            fileToWritecutarm += "\r\n"
        }
        // 6
        // Create Date
        let date = Date()

        // Create Date Formatter
        let dateFormatter = DateFormatter()
        // Set Date Format
        dateFormatter.dateFormat = "YYYYMMdd_hhmmss"

        // Convert Date to String
        let filenamecutarm = dateFormatter.string(from: date)
        print("filename:\(filenamecutarm)")

        let pathscutarm = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectorycutarm = pathscutarm[0]
        let filecutarm = documentsDirectorycutarm.appendingPathComponent("_rawPLYcutarm_\(filenamecutarm).ply")

        do {
            print("File path cutarm : " + filecutarm.absoluteString)
            print("remove prefix cutarm : \(filecutarm.absoluteString.deletingPrefix("file://"))")
            // 7
            try fileToWritecutarm.write(to: filecutarm, atomically: true, encoding: String.Encoding.ascii)
            print("file save sucessfully cutarm")
            isSavingFile = false

           // convertCloud(path: filecutarm.absoluteString.deletingPrefix("file://"))

        } catch {
            print("Failed to write PLY file2", error)
        }
        
        */
       
        
         let count = finalPoints.count
        
        
        
        
        // 1
        var fileToWritecolor = ""
        let headerscolor = ["ply", "format ascii 1.0", "element vertex \(count)", "property float32 x", "property float32 y", "property float32 z", "property uchar red", "property uchar green", "property uchar blue", "property uchar alpha", "element face 0", "property list uint8 int32 vertex_indices", "end_header"]
        for header in headerscolor {
            fileToWritecolor += header
            fileToWritecolor += "\r\n"
        }

        // 2

        for i in 0 ..< count {
            // 3
            let point = finalPoints[i]
            // let colors = point.color

            // 4
            let red = 10.0
            let green = 90.0
            let blue = 40.0

            // 5
            // let pvValue = "\(point.position.x) \(point.position.y) \(point.position.z)"
            let pvValue = "\(point.x) \(point.y) \(point.z) \(Int(red)) \(Int(green)) \(Int(blue)) 255"
            fileToWritecolor += pvValue
            fileToWritecolor += "\r\n"
        }
        // 6
        let pathscolor = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectorycolor = pathscolor[0]
        let filecolor = documentsDirectorycolor.appendingPathComponent("000.ply")

        do {
            print("File path : " + filecolor.absoluteString)
            print("remove prefix : \(filecolor.absoluteString.deletingPrefix("file://"))")
            // 7
            try fileToWritecolor.write(to: filecolor, atomically: true, encoding: String.Encoding.ascii)
            print("file save sucessfully color")
            isSavingFile = false
            // pathnameofplyfile = file.path
           
            convertCloud(path: filecolor.absoluteString.deletingPrefix("file://"))

        } catch {
            print("Failed to write PLY file", error)
        }

        
     
    }
    // convert point cloud to scn
    func saveConvertedScn(path: String) {
        print("storing scene...")
        // save model
        let success = convertedScene.write(to: URL(fileURLWithPath: path), options: nil, delegate: nil) { totalProgress, error, _ in
            print("Progress \(totalProgress) Error: \(String(describing: error))")
            print("saving... \(Int(totalProgress * 100))%")
        }
        print("File path saveConvertedScene : " + path)
        print("remove prefix saveConvertedScene : \(path.deletingPrefix("file://"))")
        print("Success: \(success)")
        pathnameofscnfile = path.deletingPrefix("file://")
        sharedViewModel.pathNameString = pathnameofscnfile.deletingPrefix("file://")
        print("path is : \(sharedViewModel.pathNameString) and \(pathnameofscnfile.deletingPrefix("file://"))")
        showrenderingScreen = true
       //  Helper().savePathnameToKeychain(pathname: pathnameofscnfilepath)
        print("pathnameofscnfilepath:" + pathnameofscnfilepath)
        Logger.shared().log(message: "pathNameString: helper() : \(String(describing: Helper().retrievePathnameFromKeychain()))")
    }
    
    
    func convertCloud(path: String) {
        Helper().savePathnameToKeychain(pathname: "")
        convertedScene = SCNScene()

        print("loading cloud...")

        DispatchQueue.global(qos: .background).async {
            let pointcloud = PointCloud()

            pointcloud.progressEvent.addHandler { progress in
                DispatchQueue.main.async {
                    print("converting... \(progress * 100)%")
                }
            }

            pointcloud.load(file: path)
            let cloud = pointcloud.getNode(useColor: true)
            cloud.name = "cloud"
            self.convertedScene.rootNode.addChildNode(cloud)

            print("loaded!")
            Helper().savePathnameToKeychain(pathname: "")
            DispatchQueue.main.async {
                let url = URL(fileURLWithPath: path)
                let output = url.deletingPathExtension().appendingPathExtension("scn")
                let usdzOutput = url.deletingPathExtension().appendingPathExtension("usdz")

                print("storing scn...")
                self.pathnameofscnfilepath = output.path
                self.saveConvertedScn(path: output.path)

                print("storing usdz...")
                let scnView = SCNView()
                scnView.scene?.write(to: usdzOutput, options: nil, delegate: nil, progressHandler: nil)
                // self.showFileSaver()

                print("done!")
                Helper().savePathnameToKeychain(pathname: "000.scn")
                NotificationCenter.default.post(name: Notification.Name("reloadviewscnuploaded"), object: nil, userInfo: [:])

            }
          
        }
    }
    
    func removeFloor(points:[simd_float3])->Float
       {
           var deltaY: Float = 0.02
           var pcdcutBottom = [simd_float3]()
           pcdcutBottom.append(contentsOf: points)
           pcdcutBottom = pcdcutBottom.sorted{$0.y < $1.y}
           var minzPoints: [[simd_float3]] = []
           var cutheightfound = false
           var maxh = pcdcutBottom[pcdcutBottom.count-1].y
           var minh = pcdcutBottom[0].y
           var tempminh = minh
           var cutheight: Float = 0
           print("min and max height",minh, maxh, pcdcutBottom.count-1)
           while(minh < maxh - deltaY)
           {
               var pointsatgivenY : [simd_float3] = []

               for i in 0..<pcdcutBottom.count
               {
                   if pcdcutBottom[i].y < minh+deltaY && pcdcutBottom[i].y > minh
                   {
                       pointsatgivenY.append(pcdcutBottom[i])

                   }

               }


//               print("point at given Y",i,pointsatgivenY.count)
               if pointsatgivenY.count != 0
               {
                   minzPoints.append(pointsatgivenY)

               }
               minh += deltaY

           }

           var countforlayer = 0
           for i in 0..<minzPoints.count-5
           {
               var testlayer = minzPoints[i]
   //            testlayer.sort{$0.x < $1.x}
   //            # firstx=testlayer[0]
               var midx = testlayer[Int(testlayer.count/2)]
               testlayer.sort{$0.z > $1.z}
               var minz = testlayer[0]
               var maxz = testlayer[testlayer.count-1]
               var midz = 3 * minz + maxz / 4
               
               for j in i+1..<i+4
               {
                   var testlayertemp = minzPoints[j]
   //                # sorted(testlayertemp,key=lambda x: x[2], reverse=False)
                   for k in 0..<testlayertemp.count
                   {
                       if(testlayertemp[k].z <= minz.z && testlayertemp[k].z >= midz.z)
                       {
                           countforlayer += 1

                       }
                       if countforlayer < 3
                       {
                           if j == i+3
                           {
                               print("cutbottom",j)
                               cutheightfound = true
                               break
                           }
                           countforlayer = 0

                       }
                       else
                       {
                           countforlayer = 0

                           break
                       }
                           
                       countforlayer = 0

                   }
                   
                 
               }
              

               if cutheightfound
               {
                   cutheight = minzPoints[i][0].y + 2 * deltaY
                   break
               }
                   
           }
           if cutheight==0{
               
               var countforlayer = 0
               for i in 0..<minzPoints.count-5
               {
                   var testlayer = minzPoints[i]
   //                testlayer.sort{$0.x < $1.x}
   //    //            # firstx=testlayer[0]
   //                var midx=testlayer[Int(testlayer.count/2)]
                   testlayer.sort{$0.z < $1.z}
                   var minz = testlayer[0]
                   var maxz = testlayer[testlayer.count-1]
                   var midz = 3 * minz + maxz / 4
                   for j in i+1..<i+4
                   {
                       var testlayertemp=minzPoints[j]
       //                # sorted(testlayertemp,key=lambda x: x[2], reverse=False)
                       for k in 0..<testlayertemp.count
                       {
                           if(testlayertemp[k].z >= minz.z && testlayertemp[k].z <= midz.z)
                           {
                               countforlayer += 1

                           }
                           if countforlayer < 3
                           {
                               if j == i + 3
                               {
                                   print("cutbottom",j)
                                   cutheightfound = true
                                   break
                               }
                               countforlayer = 0

                           }
                           else
                           {
                               countforlayer = 0

                               break
                           }
                           countforlayer = 0

                                   
                       }
                       
                     
                   }
                  

                   if cutheightfound
                   {
                       cutheight = minzPoints[i][0].y + 2 * deltaY
                       break
                   }
                       
               }
           }

   //           # cutheightglobal=cutheight
              print("cutheight bottom:",cutheight)
              return cutheight
       }
}
