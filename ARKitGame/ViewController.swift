//
//  ViewController.swift
//  ARKitGame
//
//  Created by Tyler Jaacks on 7/1/17.
//  Copyright © 2017 Tyler Jaacks. All rights reserved.
//

import UIKit
import ARKit
import GameKit

class ViewController: UIViewController, GKGameCenterControllerDelegate {
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var debugHighscoreLabel: UILabel!
    @IBOutlet weak var debugHighscoreText: UITextField!
    
    @IBAction func DebugMenuActivator(_ sender: Any) {
        alertDialog(alertTitle: "Debug Mode Activated", alertMessage: "You have activated debug mode!")
    }
    
    @IBAction func setHighScoreButton(_ sender: Any) {
        defaults.set(Int(debugHighscoreText.text!), forKey: "highscore")
    }
    
    var score:Int = 0 {
        didSet {
            counterLabel.text = "\(score)"
        }
    }
    
    var timeLeft:Int = 60 {
        didSet {
            timerLabel.text = "Time Left: " + "\(timeLeft)"
        }
    }
    
    var highScore: Int = 0 {
        didSet {
            
        }
    }
    
    var gameTime = Timer()
    
    var defaults = UserDefaults.standard
    
    var gcEnabled = Bool()
    var gcDefaultLeaderboard = String()
    
    // TODO Edit this to the actual leaderboard id.
    let LEADERBOARD_ID: String = "com.tylerj.arkitgame"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authenticateLocalPlayer()
        
        if UserDefaults.standard.object(forKey: "highscore") != nil {
            highScore = loadHighScore()
        } else {
            saveHighScore()
        }
        
        highScore = loadHighScore()
        
        let scene = SCNScene()
        
        sceneView.scene = scene
        
        gameTime = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.action), userInfo:nil, repeats:true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        
        sceneView.session.run(configuration)
        
        addObject()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: sceneView)
            
            let hits = sceneView.hitTest(location, options: nil)
            
            if let hitObject = hits.first {
                let node = hitObject.node
                
                if node.name == "ARShip" {
                    score += 1
                    node.removeFromParentNode()
                    addObject()
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func action() {
        if (timeLeft > 0) {
            timeLeft -= 1;
        } else if (score <= highScore) {
            alertDialog(alertTitle: "Your ARKit Game Score!", alertMessage: "Score is \(self.score)")
            
            self.gameTime.invalidate()
            self.score = 0
            self.timeLeft = 60
            
        } else if (score > highScore) {
            alertDialog(alertTitle: "You Broke the ARKit Game High Score!", alertMessage: "The new Highscore is \(self.score)")
            
            saveHighScore()
            
            submitUserHighScoreToGameCenter()
            
            self.gameTime.invalidate()
            self.score = 0
            self.timeLeft = 60
        }
    }
    
    func addObject() {
        let ship = Spaceship()
        ship.loadModel()
        
        let xPos = randomPosition(lowerBound: -1.5, upperBound: 1.5)
        let yPos = randomPosition(lowerBound: -1.5, upperBound: 1.5)
        
        ship.position = SCNVector3(xPos, yPos, -1)
        
        sceneView.scene.rootNode.addChildNode(ship)
    }
    
    func alertDialog(alertTitle title: String, alertMessage message: String) {
        let scoreAlert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        scoreAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in
            scoreAlert.dismiss(animated: true, completion: nil)
            
            self.gameTime = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.action), userInfo:nil, repeats:true)
        }))
        
        scoreAlert.addAction(UIAlertAction(title: "Leaderboard", style: UIAlertActionStyle.default, handler: { (action) in
            scoreAlert.dismiss(animated: true, completion: nil)
            
            self.gameTime = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.action), userInfo:nil, repeats:true)
            
            self.checkGameCenterLeaderboard()
        }))
        
        self.present(scoreAlert, animated: true, completion: nil)
    }
    
    func loadHighScore() -> Int {
        return defaults.integer(forKey: "highscore")
    }
    
    func saveHighScore() {
        highScore = score
        defaults.set(highScore, forKey: "highscore")
    }
    
    func randomPosition (lowerBound lower:Float, upperBound upper:Float) -> Float {
        return Float(arc4random()) / Float(UInt32.max) * (lower - upper) + upper
    }

    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                self.present(ViewController!, animated: true, completion: nil)
            } else if (localPlayer.isAuthenticated) {
                self.gcEnabled = true
                
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: { (leaderboardIdentifer, error) in
                    if error != nil { print(error!)
                    } else { self.gcDefaultLeaderboard = leaderboardIdentifer! }
                })
                
            } else {
                self.gcEnabled = false
                print("Local player could not be authenticated!")
                print(error!)
            }
        }
    }
    
    func submitUserHighScoreToGameCenter() {
        let bestScoreInt = GKScore(leaderboardIdentifier: LEADERBOARD_ID)
        
        bestScoreInt.value = Int64(highScore)
        GKScore.report([bestScoreInt]) { (error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("Best Score submitted to your Leaderboard!")
            }
        }
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    func checkGameCenterLeaderboard() {
        let gcVC = GKGameCenterViewController()

        gcVC.gameCenterDelegate = self
        gcVC.viewState = .leaderboards
        gcVC.leaderboardIdentifier = LEADERBOARD_ID
        present(gcVC, animated: true, completion: nil)
    }
}
