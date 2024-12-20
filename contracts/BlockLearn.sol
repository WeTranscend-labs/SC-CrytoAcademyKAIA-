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

    struct Certificate {
        uint256 courseId;
        string courseName;
        address studentAddress;
        uint256 completionDate;
        string metadata;
    }

    function _update(address to, uint256 tokenId, address auth)
    internal
    override(ERC721, ERC721Enumerable)
    returns (address)
{
    return ERC721._update(to, tokenId, auth);
}


    mapping(uint256 => Certificate) public certificates;
    mapping(address => mapping(uint256 => bool)) public completedCourses;

    event CertificateMinted(
        uint256 tokenId, 
        address student, 
        uint256 courseId, 
        string courseName
    );

    constructor(address initialOwner) 
        ERC721("BlockLearn Certificate", "BLCERT") 
        Ownable(initialOwner) 
    {}

    function mintCertificate(
        uint256 courseId, 
        string memory courseName,
        string memory metadata
    ) public returns (uint256) {
        require(!completedCourses[msg.sender][courseId], "Certificate already issued");

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

        completedCourses[msg.sender][courseId] = true;

        emit CertificateMinted(newTokenId, msg.sender, courseId, courseName);

        return newTokenId;
    }

    function getCompletedCourses(address student) 
    public 
    view 
    returns (uint256[] memory) 
{
    uint256 completedCount = 0;

    // Đếm số lượng khóa học đã hoàn thành
    for (uint256 courseId = 1; courseId <= _tokenIds.current(); courseId++) {
        if (completedCourses[student][courseId]) {
            completedCount++;
        }
    }

    // Tạo mảng để lưu danh sách khóa học đã hoàn thành
    uint256[] memory completedCoursesList = new uint256[](completedCount);
    uint256 index = 0;

    // Lặp lại lần nữa để thêm courseId vào mảng
    for (uint256 courseId = 1; courseId <= _tokenIds.current(); courseId++) {
        if (completedCourses[student][courseId]) {
            completedCoursesList[index] = courseId;
            index++;
        }
    }

    return completedCoursesList;
}


    function tokenURI(uint256 tokenId)
        public 
        view 
        override(ERC721, ERC721URIStorage) 
        returns (string memory) 
    {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://white-peculiar-hookworm-507.mypinata.cloud/ipfs/";
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Ghi đè hàm _increaseBalance để giải quyết xung đột
    function _increaseBalance(address account, uint128 value) 
        internal 
        override(ERC721, ERC721Enumerable) 
    {
        super._increaseBalance(account, value);
    }
}
