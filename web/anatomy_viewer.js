import * as THREE from 'three'
import { OrbitControls } from 'three/addons/controls/OrbitControls.js'
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js'
import { STLLoader } from 'three/addons/loaders/STLLoader.js'

const NOTEBOOK_ANATOMY_LOOK = {
  heart: { color: 0xe9a6af, opacity: 0.22 },
  aorta: { color: 0xb22222, opacity: 0.68 },
  coronary: { color: 0x4169e1, opacity: 1 },
  calcification: { color: 0xffa500, opacity: 1 },
}

const sessions = new WeakMap()

function resolveUrl(sourceUrl) {
  if (/^(https?:|blob:|data:)/i.test(sourceUrl)) return sourceUrl
  const base = document.querySelector('base')?.href || document.baseURI || location.href
  return new URL(sourceUrl, base).href
}

function disposeObject(object) {
  object.traverse((child) => {
    if (!(child instanceof THREE.Mesh)) return
    child.geometry?.dispose()
    const materials = Array.isArray(child.material) ? child.material : [child.material]
    materials.forEach((material) => material?.dispose())
  })
}

function fitModel(object, targetSize = 3.4) {
  const bounds = new THREE.Box3().setFromObject(object)
  const size = bounds.getSize(new THREE.Vector3())
  const center = bounds.getCenter(new THREE.Vector3())
  const longest = Math.max(size.x, size.y, size.z)
  if (Number.isFinite(longest) && longest > 0) {
    object.scale.setScalar(targetSize / longest)
  }
  object.position.sub(center.multiplyScalar(object.scale.x))
  object.updateMatrixWorld(true)
}

function frameOverview(object, camera, controls, direction, padding = 1.65) {
  const box = new THREE.Box3().setFromObject(object)
  const size = box.getSize(new THREE.Vector3())
  const center = box.getCenter(new THREE.Vector3())
  const radius = Math.max(size.x, size.y, size.z, 0.01) * 0.5
  const fov = (camera.fov * Math.PI) / 180
  const aspect = Math.max(camera.aspect, 0.0001)
  const fitByHeight = radius / Math.tan(fov / 2)
  const fitByWidth = radius / (Math.tan(fov / 2) * aspect)
  const distance = Math.max(fitByHeight, fitByWidth) * padding
  const offset = direction.clone().normalize().multiplyScalar(distance)

  camera.up.set(0, 1, 0)
  camera.position.copy(center).add(offset)
  camera.near = Math.max(distance / 120, 0.01)
  camera.far = Math.max(distance * 24, 100)
  camera.updateProjectionMatrix()
  camera.lookAt(center)
  controls.target.copy(center)
  controls.minDistance = distance * 0.6
  controls.maxDistance = distance * 4.5
  controls.update()
}

function classifyAnatomyRole(name) {
  const normalized = name.toLowerCase()
  if (normalized.includes('calcif') || normalized.includes('calcium')) return 'calcification'
  if (normalized.includes('coronar')) return 'coronary'
  if (normalized.includes('aorta')) return 'aorta'
  if (normalized.includes('heart') || normalized.includes('cardiac')) return 'heart'
  if (normalized.includes('centerline') || normalized.includes('centreline')) return 'centerline'
  return 'other'
}

function ancestryName(object) {
  const parts = []
  let current = object
  while (current) {
    if (current.name) parts.push(current.name)
    current = current.parent
  }
  return parts.join(' ')
}

function applyNotebookLook(root) {
  root.traverse((node) => {
    const role = classifyAnatomyRole(ancestryName(node))
    node.userData.anatomyRole = role
    node.userData.originalVisible = node.visible
    const look = NOTEBOOK_ANATOMY_LOOK[role]
    if (!look || !(node instanceof THREE.Mesh)) return
    node.renderOrder = role === 'heart' ? 0 : role === 'aorta' ? 1 : role === 'coronary' ? 2 : 3
    const next = new THREE.MeshLambertMaterial({
      color: look.color,
      opacity: look.opacity,
      transparent: look.opacity < 0.999,
      depthWrite: look.opacity >= 0.999,
      side: role === 'heart' ? THREE.FrontSide : THREE.DoubleSide,
    })
    next.userData.originalOpacity = look.opacity
    next.userData.originalTransparent = next.transparent
    next.userData.originalDepthWrite = next.depthWrite
    node.material = next
  })
}

function applyAnatomyViewMode(root, viewMode) {
  root.traverse((node) => {
    const role = node.userData.anatomyRole ?? classifyAnatomyRole(ancestryName(node))
    if (role === 'centerline') {
      node.visible = false
      return
    }
    const vesselVisible = viewMode === 'VESSEL' || viewMode === 'VESSEL_CALCIFICATION'
    const calcVisible = viewMode === 'CALCIFICATION' || viewMode === 'VESSEL_CALCIFICATION'
    const heartVisible = viewMode !== 'CALCIFICATION'
    if (role === 'coronary' || role === 'aorta') node.visible = vesselVisible
    else if (role === 'calcification') node.visible = calcVisible
    else if (role === 'heart') node.visible = heartVisible
    else node.visible = node.userData.originalVisible !== false
  })
}

function createSession(element, sourceUrl, format, viewMode, onStatus, onError) {
  let disposed = false
  let animationFrame = 0
  let loadedObject = null
  const session = {
    viewMode,
    root: null,
    dispose() {
      disposed = true
      window.cancelAnimationFrame(animationFrame)
      resizeObserver.disconnect()
      controls.dispose()
      if (loadedObject) disposeObject(loadedObject)
      renderer.dispose()
      renderer.domElement.remove()
    },
  }

  const normalizedFormat = (format || 'GLB').toUpperCase()
  const isAnatomyGlb = normalizedFormat === 'GLB' || normalizedFormat === 'GLTF'
  const scene = new THREE.Scene()
  scene.background = new THREE.Color(isAnatomyGlb ? '#050a16' : '#07111e')

  const camera = new THREE.PerspectiveCamera(38, 1, 0.01, 1000)
  camera.position.set(0, 0.35, 5.4)
  camera.up.set(0, 1, 0)

  let renderer
  try {
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false })
  } catch (error) {
    onError?.('브라우저에서 WebGL 3D 화면을 생성하지 못했습니다.')
    throw error
  }
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2))
  renderer.outputColorSpace = THREE.SRGBColorSpace
  renderer.toneMapping = isAnatomyGlb ? THREE.NoToneMapping : THREE.ACESFilmicToneMapping
  renderer.toneMappingExposure = isAnatomyGlb ? 1 : 1.15
  renderer.domElement.style.width = '100%'
  renderer.domElement.style.height = '100%'
  renderer.domElement.style.display = 'block'
  element.replaceChildren(renderer.domElement)

  const controls = new OrbitControls(camera, renderer.domElement)
  controls.enableDamping = true
  controls.dampingFactor = 0.075
  controls.screenSpacePanning = true
  controls.enableRotate = true
  controls.enableZoom = true
  controls.enablePan = true
  controls.minDistance = 1.2
  controls.maxDistance = 20

  if (isAnatomyGlb) {
    scene.add(new THREE.AmbientLight('#ffffff', 0.82))
    const keyLight = new THREE.DirectionalLight('#ffffff', 0.55)
    keyLight.position.set(1, 1, 1)
    scene.add(keyLight)
    const fillLight = new THREE.DirectionalLight('#ffffff', 0.22)
    fillLight.position.set(-0.8, 0.35, -0.6)
    scene.add(fillLight)
  } else {
    scene.add(new THREE.HemisphereLight('#d8e8ff', '#172235', 2.3))
    const keyLight = new THREE.DirectionalLight('#ffffff', 3.4)
    keyLight.position.set(4, 5, 5)
    scene.add(keyLight)
    const rimLight = new THREE.DirectionalLight('#4f8cff', 2.1)
    rimLight.position.set(-4, 1, -3)
    scene.add(rimLight)
  }

  const resize = () => {
    const width = element.clientWidth
    const height = element.clientHeight
    if (width < 8 || height < 8) return
    camera.aspect = width / height
    camera.updateProjectionMatrix()
    renderer.setSize(width, height, false)
  }
  const resizeObserver = new ResizeObserver(resize)
  resizeObserver.observe(element)
  resize()

  const report = (message) => {
    if (!disposed) onStatus?.(message)
  }

  const load = async () => {
    const url = resolveUrl(sourceUrl)
    report('3D 모델을 불러오는 중…')
    const progress = (event) => {
      if (!event.lengthComputable || !event.total) return
      report(`3D 모델 불러오는 중 ${Math.round((event.loaded / event.total) * 100)}%`)
    }
    if (isAnatomyGlb) {
      const gltf = await new GLTFLoader().loadAsync(url, progress)
      applyNotebookLook(gltf.scene)
      applyAnatomyViewMode(gltf.scene, session.viewMode)
      return gltf.scene
    }
    if (normalizedFormat === 'STL') {
      const geometry = await new STLLoader().loadAsync(url, progress)
      geometry.computeVertexNormals()
      return new THREE.Mesh(
        geometry,
        new THREE.MeshStandardMaterial({
          color: '#ef5d63',
          roughness: 0.48,
          metalness: 0.08,
          side: THREE.DoubleSide,
        }),
      )
    }
    throw new Error(`${format} 형식은 현재 3D 뷰어에서 지원하지 않습니다.`)
  }

  load()
    .then((object) => {
      if (disposed) {
        disposeObject(object)
        return
      }
      loadedObject = object
      session.root = object
      applyAnatomyViewMode(object, session.viewMode)
      if (isAnatomyGlb) {
        fitModel(object, 2.2)
        scene.add(object)
        frameOverview(object, camera, controls, new THREE.Vector3(0.52, 0.16, -1), 1.75)
      } else {
        fitModel(object)
        scene.add(object)
        controls.target.set(0, 0, 0)
        controls.update()
      }
      resize()
      report('마우스로 회전 · 휠로 확대 · 우클릭으로 이동')
    })
    .catch((error) => {
      if (!disposed) {
        onError?.(error instanceof Error ? error.message : '3D 모델을 표시하지 못했습니다.')
      }
    })

  const animate = () => {
    if (disposed) return
    controls.update()
    renderer.render(scene, camera)
    animationFrame = window.requestAnimationFrame(animate)
  }
  animate()
  return session
}

function mount(element, sourceUrl, format, viewMode, onStatus, onError) {
  const previous = sessions.get(element)
  previous?.dispose()
  element.style.width = '100%'
  element.style.height = '100%'
  element.style.overflow = 'hidden'
  element.style.background = '#050a16'
  const session = createSession(element, sourceUrl, format, viewMode, onStatus, onError)
  sessions.set(element, session)
}

function setViewMode(element, viewMode) {
  const session = sessions.get(element)
  if (!session) return
  session.viewMode = viewMode
  if (session.root) applyAnatomyViewMode(session.root, viewMode)
}

function dispose(element) {
  const session = sessions.get(element)
  if (!session) return
  session.dispose()
  sessions.delete(element)
}

window.AngioAnatomy = { mount, setViewMode, dispose }
