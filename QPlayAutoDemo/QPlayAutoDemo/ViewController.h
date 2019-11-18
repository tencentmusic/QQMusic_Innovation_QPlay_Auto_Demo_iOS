//
//  ViewController.h
//  QPlayAutoDemo
//
//  Created by travisli(李鞠佑) on 2018/11/5.
//  Copyright © 2018年 腾讯音乐. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *albumImgView;
@property (weak, nonatomic) IBOutlet UILabel *songTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *singerLabel;
@property (weak, nonatomic) IBOutlet UIButton *btnPlayPause;
@property (weak, nonatomic) IBOutlet UILabel *logLabel;
@property (weak, nonatomic) IBOutlet UIButton *btnConnect;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UIButton *btnPlayMode;
@property (weak, nonatomic) IBOutlet UIButton *btnLove;
@property (weak, nonatomic) IBOutlet UIButton *btnMore;



- (IBAction)onClickStart:(id)sender;
- (IBAction)onClickPlayPause:(id)sender;
- (IBAction)onClickPlayPrev:(id)sender;
- (IBAction)onClickPlayNext:(id)sender;
- (IBAction)onClickPlayMode:(id)sender;
- (IBAction)onClickLove:(id)sender;
- (IBAction)onSliderSeek:(id)sender;
- (IBAction)onClickMore:(id)sender;

@end

