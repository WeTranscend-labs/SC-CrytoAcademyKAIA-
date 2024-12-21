// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BlockLearnCertificate is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Constants for XP and levels
    uint256 constant BASE_XP = 100;
    uint256 constant XP_PER_LEVEL = 1000;

    struct Certificate {
        uint256 courseId;
        string courseName;
        address studentAddress;
        uint256 completionDate;
        string metadata;
    }

    struct StudentInfo {
        uint256 level;
        uint256 exp;
        uint256 completedCoursesCount;
    }

    mapping(uint256 => Certificate) public certificates;
    mapping(address => mapping(uint256 => bool)) public completedCourses;
    mapping(address => uint256[]) private _studentCompletedCourses;
    mapping(address => StudentInfo) public studentInfo;
    address[] private students;

    event CertificateMinted(
        uint256 tokenId, 
        address student, 
        uint256 courseId, 
        string courseName,
        uint256 expGained
    );
    
    event LevelUp(address student, uint256 newLevel);

    constructor(address initialOwner) 
        ERC721("BlockLearn Certificate", "BLCERT") 
        Ownable(initialOwner) 
    {}

    function updateExperience(address student, uint256 expPoints) internal {
        StudentInfo storage info = studentInfo[student];
        info.exp += expPoints;
        
        uint256 newLevel = (info.exp / XP_PER_LEVEL) + 1;
        if (newLevel > info.level) {
            info.level = newLevel;
            emit LevelUp(student, newLevel);
        }
    }

    function mintCertificate(
        uint256 courseId, 
        string memory courseName,
        string memory metadata
    ) public returns (uint256) {
        require(!completedCourses[msg.sender][courseId], "Certificate already issued");

        // Initialize student if first time
        if (studentInfo[msg.sender].level == 0) {
            studentInfo[msg.sender].level = 1;
            students.push(msg.sender);
        }

        uint256 expPoints = BASE_XP * (courseId % 3 + 1); // Simple difficulty multiplier
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, metadata);

        certificates[newTokenId] = Certificate({
            courseId: courseId,
            courseName: courseName,
            studentAddress: msg.sender,
            completionDate: block.timestamp,
            metadata: metadata
        });

        // Update student progress
        completedCourses[msg.sender][courseId] = true;
        _studentCompletedCourses[msg.sender].push(courseId);
        studentInfo[msg.sender].completedCoursesCount++;
        updateExperience(msg.sender, expPoints);

        emit CertificateMinted(newTokenId, msg.sender, courseId, courseName, expPoints);

        return newTokenId;
    }

    function getCompletedCourses(address student) 
        public 
        view 
        returns (uint256[] memory) 
    {
        require(student != address(0), "Invalid student address");
        return _studentCompletedCourses[student];
    }

    struct LeaderboardEntry {
        address student;
        uint256 level;
        uint256 exp;
        uint256 completedCourses;
    }

    function getLeaderboard(uint256 limit) 
        public 
        view 
        returns (LeaderboardEntry[] memory) 
    {
        uint256 count = students.length;
        if (limit > count) {
            limit = count;
        }

        LeaderboardEntry[] memory leaderboard = new LeaderboardEntry[](limit);
        
        // Fill and sort leaderboard
        for (uint256 i = 0; i < count; i++) {
            address studentAddr = students[i];
            StudentInfo memory info = studentInfo[studentAddr];
            
            // Find position in leaderboard based on exp
            for (uint256 j = 0; j < limit; j++) {
                if (j == i || info.exp > studentInfo[leaderboard[j].student].exp) {
                    // Shift entries down
                    for (uint256 k = limit - 1; k > j; k--) {
                        leaderboard[k] = leaderboard[k-1];
                    }
                    // Insert new entry
                    leaderboard[j] = LeaderboardEntry({
                        student: studentAddr,
                        level: info.level,
                        exp: info.exp,
                        completedCourses: info.completedCoursesCount
                    });
                    break;
                }
            }
        }
        
        return leaderboard;
    }

    // Override functions remain the same
    function _update(address to, uint256 tokenId, address auth)
        internal override(ERC721, ERC721Enumerable) returns (address)
    {
        return ERC721._update(to, tokenId, auth);
    }

    function tokenURI(uint256 tokenId)
        public view override(ERC721, ERC721URIStorage) returns (string memory) 
    {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://white-peculiar-hookworm-507.mypinata.cloud/ipfs/";
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _increaseBalance(address account, uint128 value) 
        internal override(ERC721, ERC721Enumerable) 
    {
        super._increaseBalance(account, value);
    }
}