import Foundation

var artifactoryURL = ""
var repo = ""
var repoPath = ""
var marketingVersion = ""
var artifactoryToken = ""

CommandLine.arguments.forEach { arg in
  if arg.hasPrefix("repo_path:") {
    repoPath = String(arg.split(separator: ":").last!)
  } else if arg.hasPrefix("marketing_version:") {
    marketingVersion = String(arg.split(separator: ":").last!)
  } else if arg.hasPrefix("token:") {
    artifactoryToken = String(arg.split(separator: ":").last!)
  }
}

let URL = "\(artifactoryURL)/artifactory"

guard !repoPath.isEmpty else {
  print("Please specify repo_path")
  exit(1)
}

guard !marketingVersion.isEmpty else {
  print("Please specify marketing_version")
  exit(2)
}

func shell(_ command: String) -> String {
  let task = Process()
  task.launchPath = "/bin/bash"
  task.arguments = ["-c", command]

  let pipe = Pipe()
  task.standardOutput = pipe
  task.launch()

  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String

  return output
}

let getIPAs = """
curl --insecure --silent --request GET \
--url \(URL)/api/storage/\(repo)/\(repoPath)/\(marketingVersion) \
--header 'authorization: Basic \(artifactoryToken)' | jq --raw-output '.children[].uri'
"""

print(getIPAs)

let result = shell(getIPAs)

print(result)

var top3: [String] = []

var results = result.split { $0.isNewline }

let remainsItemCount = results.count - 3
print("Remains item count is", remainsItemCount)
guard remainsItemCount > 0 else {
  print("Nothing to delete")
  exit(0)
}

results.removeLast(3)

print(results)


let group = DispatchGroup()

results.forEach { itemToDelete in
  group.enter()
  let delete = """
  curl --insecure --verbose --request DELETE \
  --url \(URL)/\(repo)/\(repoPath)/\(marketingVersion)/\(itemToDelete) \
  --header 'authorization: Basic \(artifactoryToken)'
  """
  DispatchQueue.global().async {
    print(delete)

    print(shell(delete))
    group.leave()
  }
}

group.wait()

