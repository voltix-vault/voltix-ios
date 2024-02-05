//
//  JoinKeygen.swift
//  VoltixApp

import SwiftUI
import OSLog
import CodeScanner

private let logger = Logger(subsystem: "join-committee", category: "communication")
struct JoinKeygenView: View {
    enum JoinKeygenStatus{
        case DiscoverSessionID
        case DiscoverService
        case JoinKeygen
        case WaitingForKeygenToStart
        case KeygenStarted
        case FailToStart
    }
    @EnvironmentObject var appState: ApplicationState
    @Binding var presentationStack: Array<CurrentScreen>
    @State private var isShowingScanner = false
    @State private var qrCodeResult: String? = nil
    private let serviceBrowser = NetServiceBrowser()
    @ObservedObject private var serviceDelegate = ServiceDelegate()
    private let netService = NetService(domain: "local.", type: "_http._tcp.", name: "VoltixApp")
    @State private var currentStatus = JoinKeygenStatus.DiscoverService
    @State private var keygenCommittee =  [String]()
    @State var localPartyID: String = ""
    
    var body: some View {
        VStack{
            switch currentStatus {
            case .DiscoverSessionID:
                Text("Scan the barcode on another VoltixApp")
                Button("Scan",systemImage: "qrcode.viewfinder"){
                    isShowingScanner = true
                }
                .sheet(isPresented: $isShowingScanner, content: {
                    CodeScannerView(codeTypes: [.qr], completion: self.handleScan)
                })
            case .DiscoverService:
                HStack{
                    Text("discovering mediator service")
                    if serviceDelegate.serverUrl == nil{
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.blue)
                            .padding(2)
                    } else {
                        Image(systemName: "checkmark").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/).onAppear(){
                            currentStatus = .DiscoverSessionID
                        }
                    }
                }
            case .JoinKeygen:
                Text("Join Keygen to create a new wallet").onAppear(){
                    joinKeygenCommittee()
                    currentStatus = .WaitingForKeygenToStart
                }
            case .WaitingForKeygenToStart:
                HStack{
                    Text("Waiting for keygen to start")
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.blue)
                        .padding(2)
                }.task{
                    Task{
                        repeat{
                            checkKeygenStarted()
                            try await Task.sleep(nanoseconds: 1_000_000_000)
                        }while(self.currentStatus == .WaitingForKeygenToStart)
                    }
                }
            case .KeygenStarted:
                HStack{
                    if serviceDelegate.serverUrl != nil && self.qrCodeResult != nil {
                        // at here we already know these two optional has values
                        KeygenView(presentationStack: $presentationStack, keygenCommittee: keygenCommittee, mediatorURL: serviceDelegate.serverUrl ?? "", sessionID: self.qrCodeResult ?? "",vaultName: appState.creatingVault?.name ?? "New Vault")
                    } else {
                        Text("Mediator server url is empty or session id is empty")
                    }
                }.navigationBarBackButtonHidden(true)
            case .FailToStart:
                // TODO: update this message to be more friendly, it shouldn't happen
                Text("fail to start")
            }
            
        }.onAppear(){
            logger.info("start to discover service")
            netService.delegate = self.serviceDelegate
            netService.resolve(withTimeout: TimeInterval(10))
            // by this step , creatingVault should be available already
            if appState.creatingVault == nil {
                self.currentStatus = .FailToStart
            }
            
            if let localPartyID = appState.creatingVault?.localPartyID, !localPartyID.isEmpty {
                self.localPartyID = localPartyID
            } else {
                self.localPartyID = UIDevice.current.name
                appState.creatingVault?.localPartyID = self.localPartyID
            }
        }
        
    }
    
    private func checkKeygenStarted() {
        guard let serverUrl = serviceDelegate.serverUrl else {
            logger.error("didn't discover server url")
            return
        }
        guard let sessionID = qrCodeResult else {
            logger.error("session id has not acquired")
            return
        }
        
        let urlString = "\(serverUrl)/start/\(sessionID)"
        guard let url = URL(string: urlString) else {
            logger.error("URL can't be constructed from: \(urlString)")
            return
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                logger.error("Failed to start session, error: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response")
                return
            }
            
            switch httpResponse.statusCode {
            case 200..<300:
                guard let data = data else {
                    logger.error("No participants available yet")
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let peers = try decoder.decode([String].self, from: data)
                    let deviceName = UIDevice.current.name
                    
                    if peers.contains(deviceName) {
                        self.keygenCommittee.append(contentsOf: peers)
                        self.currentStatus = .KeygenStarted
                    }
                } catch {
                    logger.error("Failed to decode response to JSON, \(data)")
                }
                
            case 404:
                logger.error("Keygen didn't start yet")
                
            default:
                logger.error("Invalid response code: \(httpResponse.statusCode)")
            }
        }.resume()
    }
    
    private func joinKeygenCommittee() {
        let deviceName = UIDevice.current.name
        guard let serverUrl = serviceDelegate.serverUrl else {
            logger.error("didn't discover server url")
            return
        }
        guard let sessionID = qrCodeResult else {
            logger.error("session id has not acquired")
            return
        }
        
        let urlString = "\(serverUrl)/\(sessionID)"
        logger.debug("url:\(urlString)")
        
        guard let url = URL(string: urlString) else {
            logger.error("URL can't be constructed from: \(urlString)")
            return
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [deviceName]
        
        do {
            let jsonEncoder = JSONEncoder()
            req.httpBody = try jsonEncoder.encode(body)
        } catch {
            logger.error("Failed to encode body into JSON string: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                logger.error("Failed to join session, error: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                logger.error("Invalid response code")
                return
            }
            
            logger.info("Joined session successfully.")
        }.resume()
    }
    
    private func handleScan(result: Result<ScanResult,ScanError>) {
        switch result{
        case .success(let result):
            qrCodeResult = result.string
            logger.debug("session id: \(result.string)")
        case .failure(let err):
            logger.error("fail to scan QR code,error:\(err.localizedDescription)")
        }
        currentStatus = .JoinKeygen
    }
}

final class ServiceDelegate : NSObject , NetServiceDelegate , ObservableObject {
    @Published var serverUrl: String?
    public func netServiceDidResolveAddress(_ sender: NetService) {
        logger.info("find service:\(sender.name) , \(sender.hostName ?? "") , \(sender.port) \(sender.domain) \(sender)")
        serverUrl = "http://\(sender.hostName ?? ""):\(sender.port)"
    }
}

#Preview {
    JoinKeygenView(presentationStack: .constant([]))
}
