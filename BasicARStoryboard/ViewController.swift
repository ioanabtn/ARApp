//
//  ViewController.swift
//  BasicARStoryboard
//
//  Created by Ioana Bostan on 10.11.2021.
//

import UIKit
import RealityKit
//1. importarea ARKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    // suprascrierea metodei de lifecycle numita viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 8. asignarea sesiunii delegate la ViewController
        arView.session.delegate = self

        // 2. setarea view-ului de AR
        // in mod normal, in Reality Kit este configurat automat, insa
        // daca dorim sa dezvoltam ceva mai avansat este important sa il scriem
        // configuram noi
        setupARView()
        
        // 4. crearea unei metode de recunoastere a gesturilor, mai exact, atunci cand
        // utilizatorul apasa pe ecran
        // scopul acesteia este de a recunoaste daca pointerul, marcat de deget,
        // interesecteaza o suprafata orizontala sau verticala
        // google UITapGestureRecognizer; self == ARView
        // definirea unui selector pentru handleTap
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
    }
    
    // 3. setup methods
    func setupARView() {
        // dezactivarea configurarii automate a AR view
        arView.automaticallyConfigureSession = false
        // definirea unei noi configuratii; google ARWorldTrackingConfiguration
        // alegem ARWorldTrackingConfiguration pentru ca vrem sa plasam un obiect
        // intr-un spatiu fizic
        let configuration = ARWorldTrackingConfiguration()
        // activarea detectiei planurilor, orizontale si verticale
        configuration.planeDetection = [.horizontal, .vertical]
        // activarea texturizarii automate a mediului
        // aceasta comanda adauga texturi si reflectii obiectelor noastre virtuale
        // astfel incat sa arate cat mai real posibil
        // valabil pentru iOS 12+
        configuration.environmentTexturing = .automatic
        // rularea noii configurari create
        arView.session.run(configuration)
    }
    
    // 5. object placement
    // objective c flag pentru #selector
    @objc
    func handleTap(recognizer: UITapGestureRecognizer) {
        // utilizatorul apasa pe ecranul telefonului, traducem acest lucru printr-o
        // locatie in ARView
        let location = recognizer.location(in: arView)
        
        // folosim raycast pentru a gasi unde se intersecteaza cu o suprafata reala
        // din locatia de unde apasam catre un plan
        // google estimatedPlane
        // momentam ne axam pe suprafete orizontale
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        
        // daca avem un rezultat, inseamna ca am gasit o suprafata orizontala
        if let firstResult = results.first {
            // pentru a plasa obiecte intr-o scena, trebuie sa ne folosim de ancore/markere
            // fiecare obiect este atasat unei ancore
            // alegem numele ancorei la fel ca numele obiectlui
            // google worldTransform
            // practic, adaugam o ancora care se afla la aceeasi orientare cu cea a suprafetei
            let anchor = ARAnchor(name: "cup_saucer_set", transform: firstResult.worldTransform)
            // adaugam ancora la sesiunea noastra
            arView.session.add(anchor: anchor)
        } else {
            // daca nu avem un rezultat, afisam un mesaj informativ
            print("We couldn't find a surface")
        }
    }
    
    // 7. plasarea obiectului
    func placeObject(named entityName: String, for anchor: ARAnchor) {
        // 7.1 crearea unui model entitate
        // fiecare obiect din scena este de fapt o entitate
        // force try! or create an optional if you're not sure the model exists
        let entity = try! ModelEntity.loadModel(named: entityName)
        
        // 7.3 adaugarea de gesturi modelelor noastre
        // generateCollisionShapes ne permite sa ne miscam in scena noastra
        // google generateCollisionShapes
        // permiterea unor operatii precum rotatia si translatia pentru modelul nostru
        entity.generateCollisionShapes(recursive: true)
        arView.installGestures([.rotation, .translation], for: entity)
        
        // 7.2 crearea unei entitate de tip ancora
        // acum ca avem acest model, vrem sa il adaugam acestei entitati ancora
        // iar apoi entitatea ancora este adaugata scenei noastre
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(entity)
        arView.scene.addAnchor(anchorEntity)
    }
}

// 6. crearea unei extensii, folosind ARKit, a ViewController
// google ARSessionDelegate
extension ViewController: ARSessionDelegate {
    // implementarea functiei didAdd anchors
    // pt ca am adaugat o ancora sesiunii noastre folosing metoda handleTap
    // odata ce avem ancora, acum vrem sa plasam obiectul in scena noastra cu ajutorul
    // acestei metode
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // pentru fiecare ancora
        for anchor in anchors {
            // daca numele ei coincide cu numele dat de noi
            if let anchorName = anchor.name, anchorName == "cup_saucer_set" {
                // plasam obiectul in scena noastra
                // plasarea obiectului cu numele ancorei pe ancora respectiva
                placeObject(named: anchorName, for: anchor)
            }
        }
    }
}
