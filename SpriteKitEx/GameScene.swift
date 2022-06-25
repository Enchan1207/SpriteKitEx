//
//  GameScene.swift
//  SpriteKitEx
//
//  Created by EnchantCode on 2022/06/22.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // ゲームシステム変数
    private var gameState: GameState = .StandBy
    private var playerScore = 0
    private var computerScore = 0
    private var lastCollidedEdge: Side? = nil
    
    // ノード
    private var ballNode: BallNode?
    private var playerPaddleNode : PaddleNode?
    private var computerPaddleNode : PaddleNode?
    
    private var playerScoreLabel: SKLabelNode?
    private var computerScoreLabel: SKLabelNode?
    
    // CP制御パラメータ
    private var elapsedTimeAfterPaddleMove: TimeInterval = .zero // パドルを動かしてからの経過時間
    private let requiredElapseTime: TimeInterval = 0.001 // 次にパドルを動かすまでに必要な時間
    private let paddleMoveRate: CGFloat = 2.5 // 一回の処理で動ける量
    
    
    override func didMove(to view: SKView) {
        initField()
        initDynamicNodes()
    }
    
    // 毎フレーム呼ばれる関数
    override func update(_ currentTime: TimeInterval) {
        
        // ミスったとき、最後にミスった方 **でない方** に得点し、次のゲームに移行させる
        if gameState == .Missed, let oppositeSide = lastCollidedEdge?.opposite(){
            addScore(oppositeSide, delta: 1)
            
            if let scoreLabel = (oppositeSide == .Player) ? playerScoreLabel : computerScoreLabel {
                scoreLabel.run(.sequence([
                    .scale(to: 1.3, duration: 0.1),
                    .run {
                        scoreLabel.text = String(self.getScore(oppositeSide))
                    },
                    .scale(to: 1.0, duration: 0.05)
                ]))
            }
            gameState = .StandBy
        }
        
        // ラリー中、要求された時間が経過していればCP側パドル移動
        let elapsedTime = currentTime - elapsedTimeAfterPaddleMove
        if gameState == .Rallying && elapsedTime >= requiredElapseTime {
            elapsedTimeAfterPaddleMove = currentTime
            stepComputerPaddle()
        }
        
    }
    
    // MARK: - タップ時の処理
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // ゲーム開始処理
        if gameState == .StandBy {
            self.gameState = .Rallying
            startProcessOfGame()
        }
        
        // ラリー中なら自機パドル移動
        if gameState == .Rallying {
            movePaddle(.Player, to: touches.first!.location(in: self))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // ラリー中なら自機パドル移動
        if gameState == .Rallying {
            movePaddle(.Player, to: touches.first!.location(in: self))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    // MARK: - ノード衝突時の処理
    
    // 衝突イベント発生時
    func didBegin(_ contact: SKPhysicsContact) {
        
        // パドルか壁にぶつかったとき ボールのy軸方向の速度ベクトルが極端に弱まっていたら、少しだけ加速する
        // (行き過ぎたトリックショットを打たせない)
        if (isBallCollided(contact, categoryMask: NodeCategory.Wall) || isBallCollided(contact, categoryMask: NodeCategory.Paddle)) &&
            abs(ballNode!.physicsBody!.velocity.dy) <= 50 {
            print("Impulse!")
            let ballDirectionY: CGFloat = (ballNode!.physicsBody!.velocity.dy > 0) ? 1.0 : -1.0
            
            ballNode!.physicsBody?.applyImpulse(.init(dx: 0, dy: ballNode!.physicsBody!.velocity.dy * 0.2 + ballDirectionY))
        }
        
        // ボールがどちらかのエッジに当たっていたら
        if let collidedEdge = getCollidedEdge(contact) {
            ballNode?.physicsBody?.velocity = .init(dx: 0, dy: 0)
            
            // 加点処理はupdateに任せる (didBegin内でNodeの更新をしてはいけないらしいため)
            // ref: https://developer.apple.com/documentation/spritekit/skphysicscontactdelegate
            lastCollidedEdge = collidedEdge
            gameState = .Missed
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
    }
    
    
    // MARK: - 関数
    
    /// フィールド初期化
    func initField(){
        // 左右エッジ設定 ここでは左右ピッタリ、上下に少しだけ(>=ボール直径) 伸ばしたエッジを作っている
        let blankHeight = (self.size.width + self.size.height) * 0.03
        let (xEdge, yEdge) = (self.size.width/2, self.size.height/2 + blankHeight)
        let rightEdge = SKPhysicsBody(
            edgeFrom: .init(x: xEdge, y: -yEdge), to: .init(x: xEdge, y: yEdge))
        let leftEdge = SKPhysicsBody(
            edgeFrom: .init(x: -xEdge, y: -yEdge), to: .init(x: -xEdge, y: yEdge))
        
        let borderBody = SKPhysicsBody(bodies: [rightEdge, leftEdge])
        borderBody.isDynamic = false // 動かない
        borderBody.restitution = 1.0 // 摩擦係数1
        borderBody.friction = 0.0 // 摩擦ゼロ
        borderBody.categoryBitMask = NodeCategory.Wall
        self.physicsBody = borderBody
        
        // 上下エッジ設定
        let topEdgeNode = EdgeNode(length: xEdge * 2)
        topEdgeNode.physicsBody!.categoryBitMask |= NodeCategory.ComputerEdge
        topEdgeNode.position = .init(x: 0, y: yEdge)
        addChild(topEdgeNode)
        
        let bottomEdgeNode = EdgeNode(length: xEdge * 2)
        bottomEdgeNode.physicsBody!.categoryBitMask |= NodeCategory.PlayerEdge
        bottomEdgeNode.position = .init(x: 0, y: -yEdge)
        addChild(bottomEdgeNode)
        
        // シーン内の物理設定
        self.physicsWorld.contactDelegate = self // 衝突時の処理
        self.physicsWorld.gravity = .init(dx: 0, dy: 0) // 重力方向
        
        // フィールドラインの設定
        let lineWidth = self.size.width * 0.01
        let lineColor: UIColor = .white
        
        let fieldSeparator = SKShapeNode(rect: .init(x: -xEdge, y: -lineWidth/2, width: xEdge * 2, height: lineWidth/2))
        fieldSeparator.fillColor = lineColor
        fieldSeparator.position = .zero
        addChild(fieldSeparator)
        
        // スコアラベルの設定
        playerScoreLabel = .init(text: "\(playerScore)")
        playerScoreLabel!.color = lineColor
        playerScoreLabel!.fontSize = 80
        playerScoreLabel!.verticalAlignmentMode = .center
        playerScoreLabel!.position = .init(x: -xEdge * 0.85, y: -50)
        addChild(playerScoreLabel!)
        
        computerScoreLabel = SKLabelNode(text: "\(computerScore)")
        computerScoreLabel!.color = lineColor
        computerScoreLabel!.fontSize = 80
        computerScoreLabel!.verticalAlignmentMode = .center
        computerScoreLabel!.position = .init(x: -xEdge * 0.85, y: 50)
        addChild(computerScoreLabel!)
    }
    
    /// 動くノードの初期化
    func initDynamicNodes(){
        // ボールノードの初期化
        let ballRadius = (self.size.width + self.size.height) * 0.01
        ballNode = .init(radius: ballRadius)
        ballNode!.position = .zero
        
        // 最初は隠しておく
        ballNode!.isHidden = true
        ballNode?.setScale(0)
        addChild(ballNode!)
        
        // 自機パドルノードの初期化
        let paddleSize = CGSize(width: self.size.width * 0.25, height: self.size.height * 0.025)
        playerPaddleNode = .init(size: paddleSize)
        playerPaddleNode!.position = .init(x: 0, y: -(self.size.height / 2) * 0.9)
        addChild(playerPaddleNode!)
        
        // CPパドルノードの初期化
        computerPaddleNode = .init(size: paddleSize)
        computerPaddleNode!.position = .init(x: 0, y: (self.size.height / 2) * 0.9)
        addChild(computerPaddleNode!)
    }
    

    func movePaddle(_ side: Side, to pos : CGPoint) {
        guard let targetPaddleNode = getPaddle(side) else {return}
        
        // 画面外に行かないように
        guard self.frame.width / 2 - abs(pos.x) >= targetPaddleNode.frame.width / 2 else {return}
        targetPaddleNode.position.x = pos.x
    }
    
    // CPパドルを次の目的地へ移動
    func stepComputerPaddle(){
        guard let ballNode = ballNode, let computerPaddleNode = computerPaddleNode else {return}
        
        // 自分サイドに来るまではなにもしない
        guard ballNode.position.y > 0 else {return}
        
        // 速度ベクトルが自分に向いていなければ動かない
        guard ballNode.physicsBody!.velocity.dy >= 0 else {return}
        
        // パドルとボールの位置関係を把握し、移動
        let xDiff = computerPaddleNode.position.x - ballNode.position.x
        let newPosition = computerPaddleNode.position.x + (xDiff > 0 ? -1 : 1) * paddleMoveRate
        movePaddle(.Computer, to: .init(x: newPosition, y: computerPaddleNode.position.y))
    }
    
    
    func getPaddle(_ by: Side) -> PaddleNode? {
        return (by == .Player) ? playerPaddleNode : computerPaddleNode
    }
    
    // ゲーム開始時の処理
    func startProcessOfGame(){
        // ボールを原点に移動し、静止させる
        ballNode?.setScale(.zero)
        ballNode?.position = .zero
        ballNode?.physicsBody?.velocity = .init(dx: 0, dy: 0)
        
        // ポップアップするアニメーションを表示し、
        ballNode?.run(.scale(to: 1.0, duration: 0.3))
        ballNode?.run(.sequence([
            .unhide(),
            .fadeIn(withDuration: 0.3),
            .wait(forDuration: 0.3)
        ]), completion: {
            
            // 最後にポイントを入れた方に向けて、ボールに初速をかける
            let ballDirectionX: CGFloat = [-1.0, 1.0].randomElement()! * .random(in: 10.0...20.0)
            let ballDirectionY: CGFloat = (self.lastCollidedEdge?.opposite() ?? .Player) == .Player ? -1.0 : 1.0
            self.ballNode?.physicsBody!.applyImpulse(.init(dx: ballDirectionX, dy: ballDirectionY * 20.0))
        })
    }
    
    /// 加点処理
    /// - Parameters:
    ///   - side: 加点する方
    ///   - delta: 点数
    func addScore(_ side: Side, delta: Int) {
        if side == .Player{
            playerScore += delta
        }
        if side == .Computer{
            computerScore += delta
        }
    }

    func getScore(_ side: Side) -> Int {
        return (side == .Player) ? playerScore : computerScore
    }
    
    /// ボールがどちらのエッジに衝突したかを返す
    /// - Parameter contact: 判定する衝突イベント
    /// - Returns: 衝突した側の `Side` の値。 ボールとエッジの衝突でない場合はnilが返ります。
    func getCollidedEdge(_ contact: SKPhysicsContact) -> Side? {
        if isBallCollided(contact, categoryMask: NodeCategory.PlayerEdge){
            return .Player
        }
        if isBallCollided(contact, categoryMask: NodeCategory.ComputerEdge){
            return .Computer
        }
        return nil
    }
    
    /// ボールが他のノードと衝突したかを返す
    /// - Parameters:
    ///   - contact: 判定する衝突イベント
    ///   - withCategoryMasks: 衝突対象を表すカテゴリマスク
    /// - Returns: 衝突しているか
    func isBallCollided(_ contact: SKPhysicsContact, categoryMask: UInt32) -> Bool{
        let contactBitMasks = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        return contactBitMasks & categoryMask == categoryMask
    }
    
}
